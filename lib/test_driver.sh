

# Executes each test passed as argument in the command line
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


# Executes a single test file in a subshell.
#
function run_test {
  local script="$1"

  [ -f "$script" ] || test_error "Test file not found: '$script'."

  # Set explicit './' path prefix for relative script paths, so that
  # `source` finds the right script:
  if [ "${script:0:1}" != '/' ]; then
    script="./$script"
  fi
  
  note "[RUNNING: $script]"

  # On a separate shell process, source the test script and then execute
  # our custom entry point:

  local pre_cmds="$(IFS=';' ; echo "${pretest_commands[*]}")"

  "$SHELL" -c "
    $pre_cmds
    _before_test_script
    source '$script'
    _after_test_script '$script'
  "
  local rc=$?

  # Check exit status
  case "$rc" in
    0) echo "All tests passed in: '$script'" ;;
    1) echo "Some tests failed in: '$script'" ;;
    3) echo "Test script did not finish (or missing invocation to 'done_testing')" ;;
    *) echo "Unknown error when executing test script (retcode: $rc)." ;;
  esac

  return "$rc"
}


function _before_test_script {
  :
}


function _after_test_script {
  local script_path="$1"
  local -a test_functions
  get_matching_functions "$script_path" "$TEST_FUNC_PATTERN" 'test_functions'

  local test_function
  for test_function in "${test_functions[@]}"; do
    _test_control begin_subtest "$test_function"
    echo
    "$test_function"
    _test_control end_subtest
  done
}
