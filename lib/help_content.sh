#!/bin/bash
#
# Copyright (C) 2025 Moisés Castañeda
# SPDX-License-Identifier: GPL-3.0-or-later
# Licensed under GPL-3.0-or-later. See LICENSE file.
#
#   Module: help_content.sh
#
#   Description:
#     Help strings that are printed by the `--help {topic}` subcommand.
#

_api_help_summary[describe]="Provides a description for the test"
_api_help_content[describe]="$(cat << 'EOF'
describe {desc}

Uses {desc} as a description for the current test.
The given value is used to format the test output.
EOF
)"


_api_help_summary[note]="Writes a comment in the test output"
_api_help_content[note]="$(cat << 'EOF'
note [-l {indent_level}] {comment}

Writes the {comment} string as a comment in the test output.
newline characters in {comment} are handled appropriately.
An indentation level {indent_level} can be specified, default is 0.
(This indentation is in addition to the current subtest indentation.)
EOF
)"


# Since the documentation for the assert  function is quite large, it is provided as a 
# man page, here we just copy the plain text version of that man page.
#
_api_help_content[assert]="$(usage 'cmdprove-assert')"
_api_help_summary[assert]="Checks a command's output against expected values"


