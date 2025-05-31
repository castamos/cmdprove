# ROADMAP

This is the wishlist for new features wanted in the `cmdprove` project.


## Make use of the `advbash` module system and standard libraries

The `advbash` module system provides cleaner module management for Bash programs, and
also provides generic utility functions that can be used to simplify the code of this
project.

## Make output fully TAP compliant

This will help integrate this test framework into automated pipelines.


## Ensure compatibility with Bash 3

Compatibility with old Bash versions is desired in order to increase adoption of this
tool, so that it can be used to add (or enhance) existing tests for legacy systems.


## Add static code verifications (linting)

To increase robustness and readability of the code.


## Include timeouts for tests

To detect unexpected hangs.


## Generate installation packages

For different package managers such as APT and RPM.


## Implement test plan declaration

So that it is required for tests to indicate how many subtests are expected to run.


## Implement versioning system for this test framework

So that tests can specify for which specific version they were written.


---
Copyright (C) 2025 Moisés Castañeda.
Licensed under GPL-3.0-or-later. See LICENSE file.
<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
