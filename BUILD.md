Detailed Build Instructions
===========================

This file contains detailed build instructions, it is mainly targeted for developers.
For basic instructions, see [README.md](README.md#building).


## Build Dependencies

[pandoc](https://pandoc.org/)
: Is used to format the documentation (including help files required for the program).
: Available in major Linux distro repos as `pandoc`.

[rsync](https://rsync.samba.org/)
: Is used for the installation step.
: Available in major Linux distro repos as `rsync`.

[codespell](https://github.com/codespell-project/codespell)
: This is a development-only dependence, used for spell-checking the whole project.
: It is used by the `check-spell` target (see below).
: Install it via pip: `pip install codespell`.


## Build Targets

### Primary (top-level) targets

Intended for direct user execution. May call secondary targets in turn.

`make all`
: Default target: builds everything necessary for installation.

`make test`
: Runs tests (for the test framework itself), including running the examples extracted
  from the documentation (via the included `mdextract` tool).

`make install`
: Installs the program and documentation under `INSTALL_PREFIX`, which defaults to
  `~/.local` (see below on how to change this).

`make clean`
: Deletes everything generated.

`make check-spell`
: Runs `codespell` on all the files in the project and prints a list of misspelled words.
: This is a sanity check expected to be run before submitting PRs.
: Note that `codespell`'s checks are heuristic and non-exhaustive.

`make fix-spell`
: Runs the spell checker in interactive mode to help fixing spelling.


### Secondary targets

These are called by the primary targets, but may be useful to execute them directly
during development.

`make exes`
: Generates (copies) executables and libraries to the build dir.

`make doc`
: Generates Man Pages and docs in other formats.

`make test-examples`
: Runs the code in the examples.

`make run-tests`
: Runs unit and integration tests.


## Generated Output

Everything the `Makefile` generates ends up inside `$(BUILD_DIR)` (i.e. `build/`).


## Configurable Variables

These are variables set with default values that can be changed in the command line as
follows:

  ```bash
  make {target} {var}={value}...`
  ```

For example:
  ```bash
  make install INSTALL_PREFIX=/opt/myprog RSYNC_EXE=/usr/remote/bin/rsync
  ```

Available configurable variables:

`INSTALL_PREFIX`
: Base directory for the installation.

`PANDOC_EXE`
: Path for the `pandoc` program.

`..._EXE`
: Similarly for the rest of the external dependency programs.

The default for external programs is to expect them to be in the PATH.

---
Copyright (C) 2025 Moisés Castañeda.
Licensed under GPL-3.0-or-later. See LICENSE file.
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
