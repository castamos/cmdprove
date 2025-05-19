#!/bin/bash
#
#   Module: help_driver.sh
#
#   Provides an interface for showing help about provided commands and the test API.
#   The actual help contents is in module `help_content.sh`.
#

# These dicts will contain the help contents, filled in by `help_content.sh`
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


