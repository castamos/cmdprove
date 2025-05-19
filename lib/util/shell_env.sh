
# Function: get_matching_functions {source_file} {func_name_pattern} {array_name}
#
#   Writes, to the array named `{array_name}`, the names of the shell functions existing
#   in the environment whose name matche the shell pattern `{func_name_pattern}` and
#   whose source file is `{source_file}`. Existing values in the output array are
#   discarded.
#
function get_matching_functions {
  local source_file="$1"
  local func_name_patn="$2"
  local -n matching_func_list="$3"

  # Save state for the `extdebug` shell option and set it to get extended function info.
  shopt -q extdebug
  local orig_extdebug=$?
  shopt -q -s extdebug

  # Get the list of all declared functions whose name matches the given pattern.
  local -a func_list
  local -a func_entry
  while read -r -a func_entry; do
    local func_name="${func_entry[2]:-}"
    case "$func_name" in $func_name_patn)
      func_list+=( "$func_name" ) 
    esac
  done < <(declare -F)

  # Mapping: function name => source line number
  local -A func_line

  # Get source file and line number for each of the functions
  local func_name
  for func_name in "${func_list[@]}"
  do
    local func_info="$(declare -F "$func_name")"

    # `func_info` is of the form: 'myfunction 123 ./my file.sh'
    # Will process it carefully to allow for spaces and other special characters in
    # file names.

    local -a info_words
    info_words=( $func_info )

    local err_pre="Internal: Invalid function declaration for '$func_name': '$func_info'"

    [ "${#info_words[@]}" -lt 3 ] && \
      test_error "$err_pre. Expected at least three fields, found ${#info_words[@]}."

    [[ "${info_words[0]}" != "$func_name" ]] && \
      test_error "$err_pre. First field should match the function name."

    [[ "${info_words[1]}" != +([0-9]) ]] && \
      test_error "$err_pre. Second field should be a positive decimal integer."
    
    local line_num="${info_words[1]}"

    # The file name is everything after the function name and line number:
    local file_start_char=$(( ${#func_name} + ${#line_num} + 2 ))
    local file_name="${func_info:$file_start_char}"

    # Discard functions not in the wanted file
    [ "$file_name" == "$source_file" ] || continue

    func_line[$func_name]="$line_num"
  done

  # Restore `extdebug` option
  if [ "$orig_extdebug" = 1 ]; then
    shopt -q -u extdebug
  fi

  dict_sort_keys_by_val 'func_line' '-gt' 'matching_func_list'
}


