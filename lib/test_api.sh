#!/bin/bash
# 
# Copyright (C) 2025 Moisés Castañeda
# SPDX-License-Identifier: GPL-3.0-or-later
# Licensed under GPL-3.0-or-later. See LICENSE file.
#
#   Module: test_api
#
#   Description:
#
#     This module contains the functions exposed to user test scripts for implementing
#     the actual tests.
#
#     For detailed descriptions of the API functions, see the `help_content.sh` module,
#     or run `cmdprove --help {api_func_name}`.
#


# Function: note [-l {indent_level}] {comment}
#
#   Writes a {comment} in the test output.
#
function note {
  local indent_level=0
  if [ $# -gt 1 ] && [ "$1" == '-l' ]; then
    indent_level="$2"; shift 2
  fi
  local prefix="# $(repeat_string '  ' $indent_level)"
  local note_prefixed="$(prefix_lines "$prefix" "$*")"
  _test_control print_indent "$note_prefixed"
}


# Function: describe {desc}
#
#   Uses {desc} as a description for the current test.
#
function describe {
  note "$1"
}


# Function: assert [-d] {description} [Options] -- {command}...
#
#   Runs a command and checks its outputs.
#   (See help_content.sh for the full explanation.)
#
function assert {
  local test_name='test'      # Set from env var TEST_NAME
  local description=
  local -a test_command
  #
  declare -A expected_arg
  declare -A expected_type
  declare -A expected_cmp
  declare -A expected_value
  declare -A expected_passed
  declare -A expected_arg_type

  shopt -s extglob
  expected_arg=(
    [out]=
    [err]=
    [ret]=
  )
  expected_passed=(
    [out]=
    [err]=
    [ret]=
  )
  expected_type=(
    # Set to 'ignore' if the corresponding flag is set;
    # otherwise set to the empty string
    [out]="${TEST_IGNORE_STDOUT:+ignore}"
    [err]="${TEST_IGNORE_STDERR:+ignore}"
    [ret]="${TEST_IGNORE_RETCODE:+ignore}"
  )
  expected_value=(
    [out]=''
    [err]=''
    [ret]=0
  )
  expected_cmp=(
    [out]='diff'
    [err]='diff'
    [ret]='diff'
  )

  #
  # Argument parsing
  debug "Assert: $@"

  # Check arguments
  if [ "${#@}" -lt 2 ]; then
    test_error "At least two arguments must be provided (description, command)."
    return;
  fi

  local opt_key=''
  local arg_count=0
  local value_needed=false
  local preserve_trailing_newlines=false
  local fail_on_error=false

  for arg in "$@"; do

    arg_count=$(( arg_count + 1 ))

    if [[ "$arg_count" = 1 ]]; then
      case "$arg" in
        -*)
          # An option was passed as first argument; do nothing here,
          # will be processed next
          ;;
        *)
          # Not an option, interpret as description
          description="$arg"
          continue
      esac
    fi

    local exp_type=
    local exp_cmp=
    local key_expect=

    if ! $value_needed; then
      case "$arg" in
        --)
          # Explicit start of command (should be the first case)
          shift "$arg_count"
          test_command=( "$@" )
          break
          ;;
        -p )  # Flag
          preserve_trailing_newlines=true
          ;;
        -f )
          fail_on_error=true
          ;;

        # Flags for excluding checks, processed below
        -oi) expected_type[out]='ignore' ;;
        -ei) expected_type[err]='ignore' ;;
        -ri) expected_type[ret]='ignore' ;;

        -*)
          # The rest of the options require a value
          opt_key="$arg"
          value_needed=true
          ;;
        *)
          test_error \
            "Invalid command-line argument given to the assert function: '$arg'," \
            "(arg index: $arg_count)" \
            "Command-line was: $@"
          exit 3;
          ;;
      esac

    else
      value_needed=false

      case "$opt_key" in
        -d ) description="$arg" ;;
          
        -o  | -e  | -r ) exp_type='string'  ; exp_cmp='diff'    ;;&
        -O  | -E  | -R ) exp_type='file'    ; exp_cmp='diff'    ;;&
        -op | -ep | -rp) exp_type='string'  ; exp_cmp='pattern' ;;&

        -o | -op | -O) key_expect=out ;;
        -e | -ep | -E) key_expect=err ;;
        -r | -rp | -R) key_expect=ret ;;

        *)
          test_error "Invalid option for 'assert()': '$opt_key'"
      esac

      expected_passed[$key_expect]=1
      expected_type[$key_expect]="$exp_type"
      expected_arg[$key_expect]="$arg"
      expected_cmp[$key_expect]="$exp_cmp"
    fi

  done


  if [ "${#test_command[@]}" == 0 ]; then
    test_error "Please specify a command to test."
    return 2
  fi

  debug "Command to test: ${test_command[@]}"
  
  # Argument validation:

  if $value_needed; then
    test_error "Missing value for option: '$opt_key'"
    return 2
  fi

  if [ -z "$description" ]; then
    test_error "Please specify a description for the test case."
    return 2
  fi

  # Populate expected values for direct comparison:
  #
  for key_expect in out err ret; do

    if [ -z "${expected_passed[$key_expect]}" ]; then
      # Not passed by the user, keep default
      continue
    fi

    # By default, do a literal string comparison
    exp_type="${expected_type[$key_expect]:-string}"
    exp_arg="${expected_arg[$key_expect]}"

    case "$exp_type" in
      ignore)
        ;;
      string|pattern)
        expected_value[$key_expect]="$exp_arg"
        ;;
      file)
        if $preserve_trailing_newlines; then
          # Read entire file:
          local exp_content
          read_file "$exp_arg" 'exp_content'
          expected_value[$key_expect]="$exp_content"
        else
          # Command-substitution chomps the value:
          expected_value[$key_expect]="$(cat "$exp_arg")"
        fi

        if [ $? != 0 ]; then
          test_error "Failed to read masterfile (type $key_expect) '$exp_arg': $!"
          return 2
        fi
        ;;
      *)
        test_error "Invalid expected value type: '$exp_type'"
        return 2
    esac
  done

  if [ "${TEST_NAME+set}" = 'set' ]; then
    test_name="$TEST_NAME"
  else
    test_name='test'
  fi
  debug "test_name set to: '$test_name'."

  # Determine paths for output files
  out_base="$TEST_OUT_DIR/$test_name"

  declare -A outfile
  outfile=(
    [out]="`get_unique_file "$out_base" .out`"
    [err]="`get_unique_file "$out_base" .err`"
    [ret]="`get_unique_file "$out_base" .ret`"
  )

  debug "STDOUT will be saved to: '${outfile[out]}'."
  debug "STDERR will be saved to: '${outfile[err]}'."
  debug "RETCODE will be saved to: '${outfile[ret]}'."

  # Execute the command to test.
  #
  # If stdin is provided to the invocation of this `assert` function, it can be consumed
  # by $command, automatically.
  #
  # It would be safer to execute the command in a subshell; however, since commands can
  # be shell functions with side effects, the subshell would prevent the test scripts to
  # observe the side effects.
  #
  # TODO: include timeout
  # TODO: verify if special characters in $command do not cause problems
  #
  debug "Running test command ..."
  local ret_code=0

  if $preserve_trailing_newlines; then
    "${test_command[@]}" \
      1> "${outfile[out]}" \
      2> "${outfile[err]}" \
      || ret_code=$?
  else
    "${test_command[@]}" \
      1> >( chomp > "${outfile[out]}" ) \
      2> >( chomp > "${outfile[err]}" ) \
      || ret_code=$?
  fi

  # Save exit code
  echo -n "$ret_code" > "${outfile[ret]}"
  local failed_checks=()

  for check in out err ret
  do
    local check_name      # Display name for this check

    if [[ "$check" == 'ret' ]]; then
      check_name='exit code'
    else
      check_name="std$check"
    fi

    if [[ "${expected_type[$check]}" == 'ignore' ]]; then
      # Ignore this check but show the output if non-empty
      local outval="$(cat "${outfile[$check]}")"
      if [[ "$outval" != *(0) ]]; then
        note "Ignoring non-empty $check_name, content was:"
        note "$outval"
      fi
      continue
    fi

    local check_type="${expected_cmp[$check]}"

    if $preserve_trailing_newlines; then
      # Direct assignment to keep trailing newlines:
      local exp_str="${expected_value[$check]}"
    else
      # The variable assignment chomps the assigned value:
      local exp_str="$(echo -n "${expected_value[$check]}")"
    fi
    
    if [[ "$check" == 'ret' && "$check_type" != 'pattern' ]]; then
      # Direct numeric comparison to decrease verbosity
      local outval="$(cat "${outfile[$check]}")"
      if [[ "$exp_str" != "$outval" ]]; then
        failed_checks+=( "$check_name" )
        note "$check_name: $outval (Expected: $exp_str)"
      fi
      continue
    fi

    local dif=$(_compare_files "$check_type" <(echo -n "$exp_str") "${outfile[$check]}")

    if [[ -n "$dif" ]]; then
      failed_checks+=( "$check_name" )
      note ''
      note "Unexpected $check_name:"
      note -l 1 "----------"
      note -l 1 "$dif"
      note -l 1 "----------"
      note -l 1 "[See: '${outfile[$check]}']"
      note ''
    fi
  done

  local fail_count="${#failed_checks[@]}"

  if [[ "$fail_count" -eq 0 ]]; then
    _test_control set_pass "$description"
  else
    _test_control set_fail "$description"
    note "Failed command checks: ${failed_checks[*]} (see above for details)."
    $fail_on_error && return "$fail_count"
  fi

  return 0
}


# Function: is {desc} [-f] [--] {left_value} {right_value}
#
#   Compares {left_value} and {right_value} for equality.
#
# Exit code:
#   - Zero, even when the comparison fails; unless -f is given.
#
function is {
  local pos=()
  local fail_on_error=false

  local arg
  for arg in "$@"; do
    shift
    case "$arg" in
      --)
        pos+=( "$@" )
        break;
      ;;
      -f)
        fail_on_error=true
      ;;
      -*)
        test_error "Invalid argument for 'is': '$arg'"
        return 2
      ;;
      *)
        pos+=( "$arg" )
    esac
  done

  if [[ "${#pos[@]}" -ne 3 ]]; then
    test_error "Expected 3 positional arguments for 'is', ${#pos[@]} were given: ${pos[@]}"
    return 2
  fi

  local desc="${pos[0]}"
  local lvalue="${pos[1]}"
  local rvalue="${pos[2]}"

  if [[ "$lvalue" == "$rvalue" ]]; then
    _test_control set_pass "$desc"
    return 0
  else
    _test_control set_fail "$desc"
    note "'$lvalue' != '$rvalue'"
    $fail_on_error && return 1
  fi

  return 0
}


# Private Function: _test_control {subcommand}
#
#  Used internally to keep track of test execution (counts for passed/failed subtests,
#  etc).
#
# Exit code:
#   - The number of failures
#
function _test_control {
  # Define globals if not present:
  : ${_pass_count:=0}
  : ${_fail_count:=0}
  : ${_test_idx:=0}
  : ${_test_level:=0}
  declare -g -a _nested_test_count
  declare -g -a _nested_test_names
  declare -g -a _nested_pass
  declare -g -a _nested_fail

  local command="${1:-}"; shift
  local desc="${1:-}"

  case "$command" in
    begin_subtest)
      local desc_label="${desc:+ - $desc}"

      # Push current counts
      _nested_test_names+=( "$desc" )
      _nested_test_count+=( "$_test_idx" )
      _nested_pass+=( "$_pass_count" )
      _nested_fail+=( "$_fail_count" )

      # Print subtest banner
      note "Subtest $((_test_idx+1))${desc_label}"

      _test_level=$((_test_level + 1))

      # Restart counts
      _test_idx=0
      _pass_count=0
      _fail_count=0
    ;;
    end_subtest)
      if [ "$_test_level" == 0 ]; then
        test_error "Subtest stack underflow"
      fi
      # Report results for the subtest
      note "$_pass_count PASSED, $_fail_count FAILED"

      local has_failures=0
      [ "$_fail_count" -gt 0 ] && has_failures=1

      # Now go back to the previous nesting level
      _test_level=$((_test_level - 1))
      local _subtest_name
      array_pop '_nested_test_names' '_subtest_name'
      array_pop '_nested_test_count' '_test_idx'
      array_pop '_nested_pass'       '_pass_count'
      array_pop '_nested_fail'       '_fail_count'

      # Set the current subtest to passed/failed 
      if [ "$has_failures" == 1 ]; then
        _test_control set_fail "$_subtest_name"
      else
        _test_control set_pass "$_subtest_name"
      fi
      _test_control print_indent ""

      return $has_failures
    ;;
    set_pass)
      local desc_label="${desc:+ - $desc}"
      _test_idx=$((_test_idx + 1))
      _pass_count=$((_pass_count + 1))
      _test_control print_indent "ok ${_test_idx}${desc_label}"
    ;;
    set_fail)
      local desc_label="${desc:+ - $desc}"
      _test_idx=$((_test_idx + 1))
      _fail_count=$((_fail_count + 1))
      _test_control print_indent "not ok ${_test_idx}${desc_label}"
    ;;
    print_indent)
      local prefix="$(repeat_string '  ' "$_test_level")"
      prefix_lines "$prefix" "$*"
    ;;
    *)
      test_error "_test_control: Unknown subcommand: '$command'"
    ;;
  esac
}

