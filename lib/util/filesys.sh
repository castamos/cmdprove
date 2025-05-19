


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


# Function: create_temp_dir
#
#   Creates a temporary directory, trying with different methods.
#
function create_temp_dir()
{
  ( # Execute all commands in a subshell with stderr closed to reduce noise )
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
      exit 1 
    fi
  ) || (
    echo "ERROR: Failed to create temp dir" >&2
    exit 1
  )
}


function get_unique_file {
  local name="$1"
  local ext="$2"
  local max_files=100

  for ((i=0; i<$max_files; i++)); do
    local candidate=`printf '%s%02d%s' "$name" $i "$ext"`
    if [ ! -e "$candidate" ]; then
      echo "$candidate" 
      return
    fi
  done

  test_error "TEST_ERROR: Could not determine a unique file name after $max_files attempts."
}
