#!/bin/bash
# 
# Copyright (C) 2025 Moisés Castañeda
# SPDX-License-Identifier: GPL-3.0-or-later
# Licensed under GPL-3.0-or-later. See LICENSE file.
#
#   Module: string.sh
#
#   Description:
#     Generic functions for string manipulation.
#


function repeat_string {
  local string="$1"
  local count="$2"

  local idx=0
  local result=
  for (( idx=0 ; idx < count ; idx+=1 )); do
    result="${result}${string}"
  done

  printf '%s' "$result"
}


function prefix_lines {
  local prefix="$1"
  local text="$2"
  local line
  
  while IFS= read -r line || [ -n "$line" ]; do
    echo "${prefix}${line}"
  done <<< "$text"
}


# Copies `stdin` to `stdout` but omits a trailing new-line character
# (if exists) from the last line.
#
chomp() {
	local last_content=""
	local empty_line_count=0
	local line
	local have_content=false
	
	# Process input line by line
	while IFS= read -r line || [ -n "$line" ]
  do
		if [ -z "$line" ]; then
			# Empty line - increment counter
			empty_line_count=$((empty_line_count + 1))
	    continue
    fi

    # Otherwise, we found a non-empty line
    # If we have previous content, print it with necessary newlines
    if $have_content; then
      printf "%s" "$last_content"
              
      # Print accumulated empty lines
      for ((i=0; i<empty_line_count; i++)); do
        printf "\n"
      done
    fi
          
    # Store this line as the last content line
    last_content="$line"
    empty_line_count=0
    have_content=true
  done
  
  # At the end, print the last content line if we have one
  # (without trailing newlines)
  if $have_content; then
    printf "%s" "$last_content"
  fi
}


