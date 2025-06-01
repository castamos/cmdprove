#!/bin/bash
# 
# Copyright (C) 2025 Moisés Castañeda
# SPDX-License-Identifier: GPL-3.0-or-later
# Licensed under GPL-3.0-or-later. See LICENSE file.
#
#   Module: filesys.sh
#
#   Description:
#     Generic functions for file-system operations.


# Function: read_file {file_path} {target_var}
#
#   Reads the entire contents of the file at {file_path} into the variable
#   named {target_var}.
#
read_file() {
  local file="$1"
  local -n content_ref="$2"

  # Read entire file plus a trailing marker character,
  # to avoid chomping trailing newlines:
  content_ref="$(cat "$file"; echo 'x')"

  # Then remove the marker
  content_ref="${content_ref%x}"
}


# Function: _compare_files {cmp_op} {file1} {file2}
#
#   Compares the contents of files {file1} and {file2} according to the comparison
#   operator {cmp_op}, which can take any of the following values:
#     'diff' - Perform and exact "diff" of the two files
#
function _compare_files {
  local cmp="$1"
  local exp="$2"
  local out="$3"

  case "$cmp" in
    diff)
      diff "$exp" "$out" 2>&1
    ;;
    pattern)
      # Note that trailing newlines are removed when assigning to variables.
      local patn="$(cat "$exp")"
      local outs="$(cat "$out")"

      case "$outs" in
        ${patn})
          return 0
        ;;
        *)
          echo "Pattern not matched: '$patn'."
          echo "Output was: '$outs'."
        ;;
      esac
    ;;
    *)
      test_error "Unknown comparison operator: '$cmp'."
    ;;
  esac
}


# Function: create_temp_dir [ {name_template} ]
#
#   Creates a temporary directory.
#   If given, the directory name is based on {name_template}.
#
#   Different methods are tried for creating the directory:
#     - mktemp command
#     - /tmp/{datetime-based-name}
#
function create_temp_dir()
{
  if ( # Execute all commands in a subshell with stderr closed to reduce noise
    exec 2>&- 

    template="$1"
    mktemp=
    dir=

    if mktemp=`command -v mktemp`; then
      if [ -n "$template" ] && dir=`$mktemp -d "$template"`; then
        echo "$dir"
      elif dir=`$mktemp -d`; then
        echo "$dir"
      fi
    elif dir="/tmp/$template/`date +%s`" && [ !-d "$dir" ] && mkdir "$dir"; then
      echo "$dir"
    else
      exit 1  # Exiting from a subshell is like a return statement.
    fi
  ); then
    return 0
  fi

  echo "ERROR: Failed to create temp dir" >&2
  return 1
}


# Function: get_unique_file {name} {ext}
#
#   Attempts to generate a name for a non-existent file (hence "unique").
#   The generated file name is of the form:
#     
#     {name}{NN}.{ext}
#
#   Where {name} can be a path with directory components, and {NN} is the smallest
#   two-digit zero-padded decimal number that makes the path unique.
#
function get_unique_file {
  local name="$1"
  local ext="$2"
  local max_files=100

  for ((i=0; i<$max_files; i++)); do
    local candidate=`printf '%s%02d%s' "$name" $i "$ext"`
    if [ ! -e "$candidate" ]; then
      echo "$candidate" 
      return 0
    fi
  done

  echo "ERROR: Could not determine a unique file name for '$name*.$ext'" \
       "after $max_files attempts." >&2
  return 1
}

