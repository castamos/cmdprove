#!/bin/bash
# 
# Copyright (C) 2025 Moisés Castañeda
# SPDX-License-Identifier: GPL-3.0-or-later
# Licensed under GPL-3.0-or-later. See LICENSE file.
#
#   Module: process.sh
#
#   Description:
#     Basic control for the running process.
#

# Set a global trap 
trap 'echo "ERROR: An unrecoverable error occurred. Aborted." >&2; exit 3' EXIT

# Finishes program execution gracefully.
function terminate {
  # Use previous' command return code, unless $1 was given
  local rc=$?
  [ -n "${1:-}" ] && rc="$1"

  trap : EXIT # Clean error msg just before exiting
  exit "$rc"
}


# Writes a message if in debug mode.
function debug {
  [ -n "$TEST_DEBUG" ] || return 0
  echo "# DBG: $*" >&2
}


# Writes a test error message and terminates the program.
function test_error() {
  echo "TEST ERROR: $@" >&2
  terminate 3
}


# Writes a fatal error message and terminates the program.
function abort() {
  echo "ERROR: $@" >&2
  terminate 2
}


# Enables Shell tracing options (for debugging).
function enable_tracing {
  set -x
  if [ "${1:-}" == '-s' ]; then
    set -o functrace
    trap 'read -p ...' DEBUG
  fi
}

