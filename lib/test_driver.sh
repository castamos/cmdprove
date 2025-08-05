#!/bin/bash
# 
# Copyright (C) 2025 Moisés Castañeda
# SPDX-License-Identifier: GPL-3.0-or-later
# Licensed under GPL-3.0-or-later. See LICENSE file.
#
#   Module: test_driver.sh
#
#   Description:
#     Entry-point functions for the test framework.
#

# Explicit map of individual subtests to run, given as:
#   {subtest_name} => {test_script}
# If empty, all tests will be run
declare -Ag subtest_inclusion_list


# Function: run_all {test_file}...
#
#   Executes each test file passed as argument.
#
function run_all {
  parse_cmdline "$@"

  if [ "${#test_file_list[@]}" = 0 ]; then
    abort "No tests given. Pass '--help' to see usage."
  fi

  case "${TEST_OUT_DIR:-}" in '')
    TEST_OUT_DIR=`create_temp_dir /tmp/command-verify.XXXX` || exit 1
  esac
  debug "Output dir: $TEST_OUT_DIR"

  # Close stdin for the current process to avoid hangs, since test should not
  # rely on it. Tests must be self-contained and provide input to stdin, if
  # needed, to the processes they are testing.
  exec 0<&-

  # Execute each test script, counting the number of failed tests
  local failures=0
  local script
  for script in "${test_file_list[@]}"; do
    if ! run_test "$script"; then
      failures=$((failures + 1))
    fi
  done

  # Set return code:
  if [ "$failures" == 0 ]; then
    terminate 0
  else
    terminate 1
  fi
}


# Function: run_test {test_file}
#
#   Executes a single test file in a subshell.
#
function run_test {
  local script="$1"

  [ -f "$script" ] || test_error "Test file not found: '$script'."

  # From the inclusion list get all the subtests corresponding to the
  # current script (if any)
  local include_subtests=()
  local subtest
  for subtest in "${!subtest_inclusion_list[@]}"; do
    if [[ "${subtest_inclusion_list[$subtest]}" == "$script" ]]; then
      include_subtests+=( "$subtest" )
    fi
  done

  # Set explicit './' path prefix for relative script paths, so that
  # `source` finds the right script:
  if [ "${script:0:1}" != '/' ]; then
    script="./$script"
  fi
  
  # Set test-script-specific environment: 
  export TEST_SOURCE_PATH="$script"
  export TEST_SOURCE_DIR="$(dirname "$script")"
  if [[ "${#include_subtests[@]}" -gt 0 ]]; then
    # Export as a single string
    export TEST_INCLUDE_SUBTESTS="${include_subtests[*]}"
  fi

  local pre_cmds="$(IFS=';' ; echo "${pretest_commands[*]}")"

  note "[RUNNING: $script]"

  # Duplicate our current stdout so that we can write to it directly from the command
  # below.
  exec {_orig_stdout_fd}>&1

  local out_err

  # On a separate shell process, source the test script along with instrumentation
  # functions to control the test execution. All functions and variables needed by the
  # instrumentation and test-assertion functions should have been marked for export at
  # this point (that is done in `bin/cmdprove`).
  #
  # We want both stdout and stderr to be written to the terminal, combined for correct
  # visualization. But we also want to capture stderr to inspect execution failures. To
  # achieve that we have the following redirections and pipes:
  #
  # a) 2>&1
  #     Connect the command's stderr to the caller's stdout, which corresponds to the
  #     pipe's stdin, i.e, the stdin of `tee`.
  #
  # b) 1>&${_orig_stdout_fd}
  #     Connect the command's stdout to the caller's file descriptor `_orig_stdout_fd`,
  #     which is the regular stdout for the test driver, duplicated above (in practice,
  #     this is the terminal).
  #
  # c) | tee >(cat >&${_orig_stdout_fd})
  #     Write `tee`'s stdin (which corresponds to the stderr of the command) to the
  #     following two outputs:
  #     c.a) The caller's stdout, which is the capturing variable `out_err`
  #     c.b) The stdin of the process substitution >(cat ...), which in turn gets copied
  #          to the caller's file descriptor `_orig_stdout_fd`, i.e. the driver's
  #          original stdout.
  #
  # Thanks to b) and c.b), the command's stdout and stderr get combined into the driver's
  # stdout. Thanks to a) and c.a), the command's stderr also gets stored in variable
  # `out_err`.
  #
  out_err=$(
    "$SHELL" -c "
      $pre_cmds
      TEST_LAST_STDERR_FILE=
      _before_test_script
      if ! source '$script'; then
        _test_control set_fail 'Non-zero retcode from sourced script: $script'
      fi
      _after_test_script '$script'
    " 2>&1 1>&${_orig_stdout_fd} | tee >(cat >&${_orig_stdout_fd})
  )
  local rc=$?

  # Close our duplicated file descriptor
  exec {_orig_stdout_fd}>&-

  # Check exit status
  case "$rc" in
    0) echo "All tests passed in: '$script'" ;;
    1) echo "Some tests failed in: '$script'" ;;
    3) echo "Test script did not finish gracefully" \
            "(or missing invocation to 'done_testing')." ;;
    *) echo "Unknown error when executing test script (retcode: $rc)." ;;
  esac

  if [[ "$rc" -ne 0 ]]; then
    local prefix='For details, see: '
    local line
    while IFS= read -rs line || [[ -n "$line" ]]; do
      case "$line" in "$prefix"*)
        local file="${line#"$prefix"}"
        if [[ -r "$file" ]]; then
          echo "-----[$file]"
          cat "$file"
          echo
          echo "-----"
        else
          log_error "Error file not found or not readable: '$file'"
        fi
      esac
    done <<< "$out_err"
  fi

  return "$rc"
}


# Callback: _before_test_script
#
#   This function is executed before each test script,
#   inside the test subshell.
#
function _before_test_script {
  trap '_test_script_exit_trap' EXIT
  set -Eeu
  set -o pipefail
  shopt -s extglob

  # Duplicate stderr to a file descriptor reserved by the shell, so we can write to the
  # actual process stderr from the EXIT trap, even if the exiting command has
  # active redirections.
  exec {_orig_stderr_fd}>&2
}


function _test_script_exit_trap {
  if [[ $? -eq 0 ]]; then
    return 0
  fi

  # The output of the following commands is redirected to the original stderr of the
  # process.  This is necessary because we can get in this "trap" from a function that
  # has its stderr redirected.
  (
    echo "ERROR: Test script execution failed."

    if [[ -n "$TEST_LAST_STDERR_FILE" ]]; then
      echo "For details, see: $TEST_LAST_STDERR_FILE"
    fi
  ) >&$_orig_stderr_fd 2>&1

  exit 3
}


# Callback: _after_test_script
#
#   This function is executed after each test script,
#   inside the test subshell.
#
function _after_test_script {
  local script_path="$1"

  local -a test_functions
  get_matching_functions "$script_path" "$TEST_FUNC_PATTERN" 'test_functions'

  # Check if a list of specific subtests to run was given
  local subtest_list="${TEST_INCLUDE_SUBTESTS:-}"
  local subtests=( $subtest_list )
  local -A executed_subtests
  local subtest
  for subtest in "${subtests[@]}"; do
    executed_subtests[$subtest]=false
  done

  local do_filter=false
  [[ "${#subtests[@]}" -gt 0 ]] && do_filter=true

  local failure_count=0
  local test_function
  for test_function in "${test_functions[@]}"
  do

    if $do_filter; then
      if [[ -v executed_subtests[$test_function] ]]; then
        # Flag the function as executed
        executed_subtests[$test_function]=true
      else
        # Subtest is not in the inclusion list
        continue
      fi
    fi

    _test_control begin_subtest "$test_function"

    # Execute test function, and check its return code
    if ! "$test_function"; then
      _test_control set_fail "Non-zero retcode from test function: '$test_function'"
    fi
    _test_control end_subtest || : $((failure_count+=$?))
  done

  # Check if inclusion list was fulfilled
  if $do_filter; then
    for subtest in "${subtests[@]}"; do
      if ! ${executed_subtests[$subtest]}; then
        test_error \
          "'$subtest': Subtest in inclusion list not found in script: '$script_path'"
        : $((failure_count++))
      fi
    done
  fi

  trap EXIT # Remove trap
  [[ "$failure_count" -eq 0 ]] # Set exit status
}

