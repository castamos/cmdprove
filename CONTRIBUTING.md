# CONTRIBUTING

Thanks for your interest in contributing to this project!

See the [ROADMAP](ROADMAP.md) for missing features we want to implement.

This document contains guidelines for code contributions.  These are not strict rules;
however the more your pull requests adhere to them, the greater the chance to get them
accepted.


## Philosophy

As stated in the [Scope section of the README](README.md#scope), this test framework is
intended to be simple and easy to use, for adding output checks for command-line projects
and Bash functions.  We also want the framework to be as portable as possible.  As such,
we will be careful when adding new functionality, especially for functionality not
recorded in the [ROADMAP](ROADMAP.md).


## Quality Assurance

- Add unit tests for new functionality
- Check spelling of new code/text (run `make check-spell`)


## Bash Coding Guidelines

For code-related contributions, adherence to the following guidelines increases the
chances of PRs being accepted.


### Avoid using external tools as much as possible

Instead of using tools such as `sed`, `grep`, `awk` or even `perl`;
implement functions in pure Bash using constructs/builtins such as `case`,
`read`, `[[ ... ]]`, etc.

We aim for this project to work reliably on any Unix-like operating system where the
right version of Bash is available; however, we don't have control over the available
versions/flavors of other system tools, and therefore making use of them would make
this test framework less reliable.

There could be legitimate and exceptional cases, however, in which an external tool is
really needed (e.g. it would be overly complicated to implement important functionality
in Bash). In such cases, only POSIX-compliant tools and options should be used, and the
tools *must* be listed under _EXTERNAL DEPENDENCIES_ in the [](README.md) file.


### Do not use undefined variables or provide defaults

Actually you can't use undefined variables even if you wanted because the framework runs
with `set -u` enabled (for details run `help set` in Bash).  When there is a possibility
that a variable is undefined, provide a default value: `${variable:-default}`; the
default may be the empty string: `${variable:-}`.


### Make sure functions return zero on success and non-zero on failure

The framework runs with `set -eE` enabled (see `help set`); therefore, any command
(including function calls) returning a non-zero code and executed outside
condition-checking statements will result in immediate abort of the whole framework.


### Use `$(command args)` instead of backticks ``command args``

For "Command Substitution", `$( ... )` is more readable and allows nesting.


### For conditionals use `[[ ... ]]` instead of `[ ... ]`

Never use `[ ... ]`, it is not reliable in general.


### Quote everything unless non-quoting is required and you know what you are doing

Always quote _Parameter Expansions_ (i.e. whenever a variable's value is used) and
_Command Substitutions_ (i.e. when using the output of a command). For example:

  ```bash
  nested_output="$(outer_command "$arg_a1" "$(inner_command "$arg_b1" "$arg_b2")")"
  ```

(Actually, in the previous example the outer quotes--and only those, could be omitted, 
but better to keep them for consistency.)

There are legitimate cases, however, in which non-quoting is necessary and/or useful, but
this should be used wisely. For example:

  ```bash
  # Flags that make use of the commands `true` and `false`.
  is_debug=true
  if $is_debug; then
    echo "Debugging message"
  fi
  ```

In general, remember that despite providing high-level control flow constructs and
operators, *Shell Scripting is in the first place a text-based macro expansion language*
(run this to convince yourself: `man bash | grep -i expansion`).  This could be a feature
one can take advantage of, if quoting wisely; or a bug otherwise.


