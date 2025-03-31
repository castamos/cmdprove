
# NAME

`cmdprove` - A test framework for command-line programs and shell scripts.

# SYNOPSIS

```bash
cmdprove [options] {test}...
```

# DESCRIPTION

Runs each test file passed as argument `{test}`. Test files are shell (Bash) scripts that
are provided with test funcions for performing checks and reporting test results.

Each test file is sourced by this program (which is itself a Bash script), in an
environment where the test functions are present; therefore tests do not need to source
(import) anything.


# TEST FILES

This is a simple example test file:

  ```bash
  # filename: sample-test-01.sh
  #------------------------

  # If tests are in a different file, here we would source
  # the actual file(s) we want to test:
  #   source program-to-test.sh

  # Then, to simplify assertions, we can define helper functions
  # that encapsulate the functionality we want to test.
  # (Here we have just trivial one-liners as examples.)
  function some_output    { echo -n "my_output: $1"; }
  function some_error     { echo -n "my_error: $1" >&2 ; }
  function this_succeeds  { return 0; }
  function this_fails     { return 1; }
  function fails_with_err { echo -n 'bad' >&2; return 2; }

  # Provide a general description for the test file, using
  # the provided 'describe' function:
  describe "A sample test file"
  
  # Finally, run the actual checks by means of the provided
  # 'assert' function, which runs the command passed after
  # '--' and checks any combination of stdout (`-o`),
  # stderr (`-e`) and retcode (`-r`).
  assert "Check stdout" -o 'my_output: foo' -- some_output foo
  assert "Check stderr" -e 'my_error: foo'  -- some_error foo
  assert "Is retcode zero"     -- this_succeeds
  assert "Is retcode one" -r 1 -- this_fails
  assert "Error and retcode" -r 2 -e 'bad' -- fails_with_err
  #------------------------
  ```

When testing multiple functionality from a single test file, assertions can be organized
into test functions. All functions whose name begins with `test_` are executed as tests:

  ```bash
  # filename: sample-test-02.sh
    assert 'Single substitution' -o 'subs-TI-tution' \
      -- bash -c 'word=substitution; echo -n "${word/ti/-TI-}"'
  # Tests arithmetic operations in Bash.
  function test_arith {
    local x=4
    assert 'Increment' -o 5 -- echo -n $(( ++x ))
    assert 'Decrement' -o 4 -- echo -n $(( --x ))
  }

  # Tests string operations in Bash.
  function test_string {
    # Here we invoke independent instances of `bash`.
    assert 'Single substitution' -o 'subs-TI-tution' \
      -- bash -c 'word=substitution; echo -n "${word/ti/-TI-}"'
    assert 'Multiple substitution' -o 'subs-TI-tu-TI-on' \
      -- bash -c 'word=substitution; echo -n "${word//ti/-TI-}"'
  }
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

