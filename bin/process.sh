
trap 'echo "ERROR: An unrecoverable error occurred. Aborted." >&2; exit 3' EXIT

# Finish program execution gracefully
#
function terminate {
  # Use previous' command return code, unless $1 was given
  local rc=$?
  [ -n "${1:-}" ] && rc="$1"

  trap : EXIT # Clean error msg just before exiting
  exit "$rc"
}


# Writes a message if in debug mode
function debug {
  [ -n "$TEST_DEBUG" ] || return 0
  echo "# DBG: $*" >&2
}


function test_error() {
  echo "TEST ERROR: $@" >&2
  terminate 3
}


function abort() {
  echo "ERROR: $@" >&2
  terminate 2
}


function enable_tracing {
  set -x
  if [ "${1:-}" == '-s' ]; then
    set -o functrace
    trap 'read -p ...' DEBUG
  fi
}


