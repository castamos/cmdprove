cmdprove
========

A testing utility for (non-interactive) command-line programs and Bash functions.

This project is intended to be a simple, portable test framework, providing a quick way
to add simple integration tests for non-interactive command-line programs, and unit tests
for Bash functions, without getting too much in the developer's way.


Usage
-----

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

By default, both stdout and stderr are expected to be empty; the return code is expected
to be zero.


Detailed Documentation
----------------------

For details see the man pages for `cmdprove` and `cmdprove-assert`:

- [cmdprove(1)](doc/cmdprove.md)
- [cmdprove-assert(1)](doc/cmdprove-assert.md)


Scope
-----

This is a simple test framework to check the output from command-line programs and Bash
functions.  For more advanced testing we recommend using (perhaps in addition to
`cmdprove`) other fully-fledged test frameworks such as [pytest](pytest.org) for Python
or [Test2](https://perldoc.perl.org/Test2) for Perl.


Dependencies and Portability
----------------------------

This framework should work properly on any Unix/Linux-like environment where Bash 4.3 or
superior is available.  A few external utilities are also required, for details refer to
`cmdprove`'s man page [cmdprove(1)](doc/cmdprove.md)


Build Instructions
------------------

## Requirements

- [pandoc](https://pandoc.org/) is used to format the documentation (required for building).
- [rsync](https://rsync.samba.org/) is used for the installation step.

To install the dependencies on Debian (and derivatives), just run:
  ```bash
  sudo apt install pandoc rsync
  ```

Building
--------

A `Makefile` is provided for building/testing/installing this project.
To do so, run the following commands at the project's root:

  ```bash
  make          # Requires `pandoc`
  make test
  make install  # Requires `rsync`
  ```

By default, installation is done under `~/.local`; to change that, run:
  ```bash
  make install INSTALL_PREFIX=/some/dir
  ```
Replacing `/some/dir` by your desired installation directory, such as `/usr/bin`.

For details, see [BUILD.md](BUILD.md).


License
-------

cmdprove is free software: you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

cmdprove is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
cmdprove. If not, see <https://www.gnu.org/licenses/>.


See top-level file: [LICENSE](LICENSE).


Contributing
------------

Contributions are welcome for:

- Bug fixes
- Implementation of missing features described in the [ROADMAP](ROADMAP.md)

For details, see: [CONTRIBUTING](CONTRIBUTING.md)


Contact
-------

`<castamos@gmail.com>`

---
Copyright (C) 2025 Moisés Castañeda.
Licensed under GPL-3.0-or-later. See LICENSE file.
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
