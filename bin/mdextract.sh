#!/bin/bash
set -Eeu
set -o pipefail
trap 'echo "ERROR: An unrecoverable error occurred. Aborted." >&2; exit 3' EXIT
shopt -s extglob


# Globals:
debug=0


# Echoes usage string to stdout
#
function usage {
  local name="$(basename "$0")"
  cat <<EOF
USAGE

    $name

DESCRIPTION

    Extracts code blocks from a Markdown (*.md) docuent passed in stdin.
EOF
}


# Entry point
#
function main {
  parse_cmdline "$@"
  process
  local rc=$?
  trap : EXIT # Clean error msg just before exiting
  return "$rc"
}


# Actual processing
#
function process {
  local backticks='```'     # Code block delimiter string
  local lang_patn='*([[:word:]])'     # Pattern for language specifications
  local indent_patn='*([[:blank:]])'  # Pattern for matching indentation
  local indent_size=0       # Characters in the indentation string
  local indent=             # The actual indentation string
  local line_num=0          # Current line number in the input file
  local block_start=0       # Line at which the current/last code block started
  local state=out           # Whether we are inside a code block
  local block_name=         # Output file name for the current block
  local block_num=0         # Count of code blocks found
  local line                # The current text line read from the input

  # Pattern for 'filename' tags:
  # - Anything not being a word character (to allow for comment specifiers)
  # - The literal: 'filename:'
  # - Optional blanks
  local fname_tag_patn='*([^[:word:]])filename:*([[:blank:]])'
  # Valid file name: Non-empty string of word, ., -, /, chars
  local fname_patn='+([.-/[:word:])'

  while read -rs; do
    line="$REPLY"
    line_num=$((line_num + 1))
    dbg "$line_num: $state: $line"

    if [ "$state" == 'out' ]; then
      case "$line" in ${indent_patn}${backticks}${lang_patn})
        state=in
        start_ln=$line_num
        block_num=$((block_num + 1))
        local content="${line##$indent_patn}"
        indent_size=$(( ${#line} - ${#content} ))
        indent="${line:0:$indent_size}"
      esac
    else # state == in
      # Remove indentation:
      local content="${line:$indent_size}"
      local this_indent="${line:0:$indent_size}"

      # Check this line, if not blank, starts with the expected indentation:
      case "$line" in !(*([[:blank:]])))
        if [ "$this_indent" != "$indent" ]; then
          local block_info="${block_name:+ (Block name: $block_name)}"
          abort \
            "Line $line_num: "\
            "Mismatched indentation: '$this_indent', expected: '$indent'\n"\
            "When processing code block $block_num started at line ${start_ln}${block_info}"
        fi
      esac

      # Check if this is a block termination sequence
      case "$content" in $backticks)
        state=out
        block_name=
        continue
      esac

      # Check if file name was provided on the first block line:
      if [ $((line_num - start_ln)) == 1 ]; then
        case "$line" in
          ${fname_tag_patn}*)
            local fname="${line##$fname_tag_patn}"
            block_name="${fname%%*([:blank:])}"
            case "$fname" in !($fname_patn))
              abort "Line $line_num: Invalid filename: '$block_name' for block $block_num"
            esac
          ;;
          *)
            # If not given, generate a name for the output file
            block_name="$(printf 'snip_%02d.txt' $block_num)"
          ;; 
        esac
        echo "Writing snippet: '$block_name'" >&2
        echo -n '' > "$block_name"
      fi

      # Append lines to the output file. NOTE: Better to open the file once.
      printf '%s\n' "$line" >> "$block_name"
    fi
  done
}


# Parses and validates command line, setting globals accordingly.
#
function parse_cmdline {
  if [ $# -lt 0 -o $# -gt 0 ]; then                                                       
    usage >&2                                                                             
    exit 1                                                                                
  fi
}


# Prints a message to stderr if in debug mode.
#
function dbg {
  if [ "${debug:-}" = 1 ]; then
    echo "$1" >&2
  fi
  return 0
}


# Prints a message to stderr and terminates the program.
#
function abort {
  echo -e "ERROR: $@" >&2
  exit 2
}


main "$@"
