cmdprove
========

A testing utility for (non-interactive) command-line programs and shell functions.

Multiple test scripts can be passed as arguments to the `cmdprove` program:

  ```bash
  cmdprove [options] {test_script}...
  ```

Where each `{test_script}` is a Bash script like the following:

  ```bash
  # filename: sample-test-readme-01.sh

  # This helper function won't be executed as a test, but can be called from tests.
  tr_helper() {
    # Just pass $3 as `tr`'s stdin.
    tr "$1" "$2" <<<"$3"
  }

  # This is a test function.
  test_tr_with_helper() {
    describe "Simple tests for the 'tr' command using a helper function"
    assert "To uppercase" -o 'HELLO WORLD!' -- tr_helper 'a-z' 'A-Z' "Hello world!"
    assert "To lowercase" -o 'hello world!' -- tr_helper 'A-Z' 'a-z' "Hello World!"
  }

  # Another test function. Note that `assert`'s stdin is passed to the command under
  # testing, therefore our `tr_helper()` is not really necessary.
  test_tr_direct() {
    describe "Simple tests for the 'tr' character translation command"
    assert "To uppercase" -o 'HELLO WORLD!' -- tr 'a-z' 'A-Z' <<<"Hello world!"
    assert "To lowercase" -o 'hello world!' -- tr 'A-Z' 'a-z' <<<"Hello World!"
  }

  # A test that checks stderr.
  test_stderr() {
    describe "Checking stderr"
    assert "Gets expected error" -e "Something Bad!" \
      -- bash -c 'echo "Something Bad!" >&2'
  }

  # A test using pattern-matching:
  test_date() {
    describe "Checks for the `date` command"

    # Patterns are extglobs.
    # NOTE: Patterns should be quoted to avoid file expansion by the shell:
    assert "Unix epoch is a number" -op '+([0-9])' -- date '+%s'

    local dd='[0-9][0-9]'
    assert "Valid time format" -op "$dd:$dd:$dd" -- date '+%T'
  }
  ```

All the functions whose names start with `test_` are identified as test functions and
are executed by `cmdprove` in the order in which they appear in the test script.

Both the `describe` and the `assert` functions (in addition to others) are provided in
the environment of the test scripts.

As shown, `-o {string}` means comparing stdout for equality to a literal string, while
`-op {extglob}` performs pattern matching.  Use `-O {file}` to compare against the
contents of a file.  There are analogous options (`-e`, `-ep`, `-E`) for checking stderr;
and (`-r`, `-R`) for checking the command's return code.

By default, both stdout and stderr are expected to be empty; the return code is exepected
to be zero.


For details see the man pages for `cmdprove` and `cmdprove-assert`:

- [cmdprove(1)](doc/cmdprove.md)
- [cmdprove-assert(1)](doc/cmdprove-assert.md)

