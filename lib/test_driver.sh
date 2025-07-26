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

  # On a separate shell process, source the test script and then execute
  # our custom entry point:
  note "[RUNNING: $script]"
  "$SHELL" -c "
    $pre_cmds
    _before_test_script
    if ! source '$script'; then
      _test_control set_fail 'Non-zero retcode from sourced script: $script'
    fi
    _after_test_script '$script'
  "
  local rc=$?

  # Check exit status
  case "$rc" in
    0) echo "All tests passed in: '$script'" ;;
    1) echo "Some tests failed in: '$script'" ;;
    3) echo "Test script did not finish gracefully" \
            "(or missing invocation to 'done_testing')." ;;
    *) echo "Unknown error when executing test script (retcode: $rc)." ;;
  esac

  return "$rc"
}


# Callback: _before_test_script
#
#   This function is executed before each test script,
#   inside the test subshell.
#
function _before_test_script {
  set -Eeu
  set -o pipefail
  shopt -s extglob
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

  return "$failure_count"
}

