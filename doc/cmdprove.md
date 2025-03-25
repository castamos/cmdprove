
# NAME

`cmdprove` - A test framework for Bash scripts.

# SYNOPSIS

```bash
cmdprove [options] {test}...
```

# DESCRIPTION

Runs each test file passed as argument `{test}`. Test files are shell (Bash) scripts that are
provided with test funcions for performing checks and reporting test results.

Each test file is sourced by this program (which is itself a Bash script), in an
environment where the test functions are present; therefore tests do not need to source
(import) anything.


# TEST FILES

This is an example test file:

  ```bash
  # file: sample-test-01.sh
  #------------------------

  # First, define the actual functions we want to test, or helper functions that
  # encapsulate what we want to test. Here they are just trivial one-liners.

  function some_output { echo -n "the output: \$1"; }
  function some_error  { echo -n "the error: \$1" >&2 ; }
  function succeeds    { return 0; }
  function fails       { return 1; }

  # Provide a general description for the test, using the provided 'describe' function:
  describe "A sample test file"
  
  # Finally, run the actual checks by means of the provided 'assert' function, which
  # runs the command passed after '--' and checks any combination of stdout / stderr /
  # retcode.

  assert "Check stdout" -o 'the output: foo' -- some_output foo
  assert "Check stderr" -e 'the error: foo'  -- some_error foo
  assert "Is retcode zero"     -- succeeds
  assert "Is retcode one" -r 1 -- fails
  #------------------------
  ```

# OPTIONS

`--help`
: Print this message and exit.

`--debug`
: Run the tests in debug mode, printing additional messages.


# ENVIRONMENT

`TEST_DEBUG`
: Setting this var to 1 is equivalent to passing option '--debug'.

`TEST_OUT_DIR`
: Where to write test output, if not provided a temporary directory is used.

These variables are always availabe in test files.


# EXIT CODE

0
: If all tests passed

1
: If some tests failed

2
: In case of error


# SEE ALSO

*cmdprove-assert*(1)

