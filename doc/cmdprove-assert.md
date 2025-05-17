# NAME

`assert` - Test API function for checking the output of a command.


# SYNOPSIS

    assert [-d] {description} [Options] -- {command}...


# DESCRIPTION

Performs a basic assertion by comparing a command's output against expected values.
By default, empty strings are expected from `stdout` and `stderr`, other values can
be specified independently for each of them. A zero return code is also expected by
default, but a different value can be specified.


# PARAMETERS

`{description}`
: A message to describe the assertion being tested (mandatory).

`{command}...`
: Command line to test (command and arguments). Must be preceded by `--`.


## OPTIONS

`-d {description}`
: Since the description is mandatory, specifying `-d` before it is optional.
: If `-d` is not given, then `{description}` must be the first argument.

`-p`
: Preserve trailing newlines. By default, trailing newlines, both in command outputs and
  in expected values/patterns, are discarded when comparing/matching. This flag reverts
  that behavior.

`(-o | -op | -O ) {expected_output}`
: Compare the `command`'s stdout against `expected_output`, which will be interpreted
  as a literal string (`-o`), as an *extglob* shell pattern (`-op`), or as a file path to
  read (`-O`).

`(-e | -ep | -E) {expected_error}`
: Like (`-o`, `-op`, `-O`) but compare `command`'s stderr.
: If not given, stderr will be expected to be the empty string ('').

`(-r | -R) {expected_retcode}`
: Like (`-o`, `-O`) but compare `command`'s return code.
: If not given, a 0 (zero) return code will be expected.

`--`
: A literal argument `--` signals the end of option parsing.
: This argument is mandatory, the rest of the arguments following it are the command to
  test.


# ENVIRONMENT

`TEST_NAME`
: User defined test name; defaults to `'test'`.
: If not set, test output files are named: `test_01.out`, `test_02.out`, etc.

`TEST_OUT_DIR`
: Directory where output files will be written to.


# OUTPUT

A message representing the result of the test.

