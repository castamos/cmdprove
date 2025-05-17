#!/bin/bash
#
#   Module: help
#
#   Provides an interface for showing help about provided commands and the test API.
#

declare -A _api_help_content
declare -A _api_help_summary


# Function: usage [ {man_page} ]
#
#   Echoes the text version of the internal manual page named `{man_page}`.
#   Default is `cmdprove`.
#
function usage {
  local man_page="${1:-cmdprove}"
  local manual="$doc_path/$man_page.txt"
  [[ -f "$manual" && -r "$manual" ]] || abort "Documentation not found: '$manual'"
  cat "$manual"
}


# Function: help_api {topic}
#
#   Echoes, to stdout, the help corresponding to {topic}, where {topic} is an API
#   function name or a help concept.
#
function help_api {
	local topic="$1"

  if [[ "$topic" == 'summary' ]]
  then
    _help_api_summary
  elif [[ -v _api_help_content[$topic] ]]
  then
    echo "${_api_help_content[$topic]}"
  else
    echo -e "Unknown help topic: '$topic'. Available topics:\n"
    _help_api_summary
  fi
}


# Function[private]: _help_api_summary
#
#   Prints a summary of the help topics.
#
function _help_api_summary {
  local -a topics
  sort_args_into 'topics' '<' "${!_api_help_summary[@]}"

  local topic
  for topic in "${topics[@]}"; do
    printf "%-10s - %s\n" "$topic" "${_api_help_summary[$topic]}" 
  done
}


# Since the documentation for this function is quite large, it is provided as a man page,
# here we just copy the plain text version of that man page.
_api_help_content[assert]="$(usage 'cmdprove-assert')"
_api_help_summary[assert]="Checks a command's output against expected values"


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

