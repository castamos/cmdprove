#!/bin/bash
#
#   Module: help_content.sh
#
#   Actual help strings.
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
note {message}

Writes {message} as a comment in the test output.
Use this function instead of a plain `echo`, so that the output is correctly formatted.
EOF
)"


# Since the documentation for the assert  function is quite large, it is provided as a 
# man page, here we just copy the plain text version of that man page.
#
_api_help_content[assert]="$(usage 'cmdprove-assert')"
_api_help_summary[assert]="Checks a command's output against expected values"


