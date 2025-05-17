#!/bin/bash
#
# Module: data_manip
#
#   Generic functions for data manipulation (in arrays and dictionaries).
#


# Function: is_sort_op {cmp_op}
#
#   Checks whether `{cmp_op}` is a valid sorting operator for binary comparisons in
#   `[[ ... ]]` constructs.
#
function is_sort_op {
  local op_ptn="@(>|>=|<|<=|-lt|-le|-gt|-ge)"
  [[ "${1:-}" == $op_ptn ]]
}


# Function: array_pop {array} {target_var}
#
#   Writes the value of the last element in the array named `{array}`
#   to the variable named {target_var}, and removes it from the array.
#
function array_pop {
  local -n the_array="$1"
  local -n target_var="$2"
  target_var="${the_array[-1]}"
  unset the_array[-1]
}


# Function: array_sort {array} {cmp_op}
#
#		Sorts, in place, the array named `{array}` by its values according to the comparison
#		operator {cmp_op}.
#
function array_sort {
	local -n array="$1"
  local cmp_op="$2"

  is_sort_op "$cmp_op" || abort "Invalid comparison operator: '$cmp_op'"

	local i j n="${#array[@]}"

  # Bubble sort
  for ((i = 0; i < n-1; i++)); do
    for ((j = 0; j < n-i-1; j++)); do
      if ! eval [[ "${array[j]}" "$cmp_op" "${array[j+1]}" ]]
      then
        local temp="${array[j]}"
        array[j]="${array[j+1]}"
        array[j+1]="$temp"
      fi
    done
  done
}


# Function: sort_args_into {array} {cmp_op} {arg}...
#
#   Writes the given arguments `{arg}...` into the array named `{array}`, sorted by the
#   comparison operator `{cmp_op}`.
function sort_args_into {
  local -n sorted="$1"; shift
  local cmp_op="$1"; shift

  is_sort_op "$cmp_op" || abort "Invalid comparison operator: '$cmp_op'"

  sorted=( "$@" )
  array_sort 'sorted' "$cmp_op"
}


# Function: dict_sort_keys_by_val {dict} {cmp_op} {sorted_keys}
#
#   Sorts, according to the comparison operator `{cmp_op}`, the keys of dictionary named
#   `{dict}` by their corresponding values.  The sorted keys are stored in the array
#   named `{sorted_keys}`.  Existing values in this array are removed.
#
function dict_sort_keys_by_val {
  local -n dict="$1"
  local cmp_op="$2"
  local -n keys="$3"

  is_sort_op "$cmp_op" || abort "Invalid comparison operator: '$cmp_op'"

  keys=( "${!dict[@]}" )

  local i j n=${#keys[@]}

  # Bubble sort
  for ((i = 0; i < n-1; i++)); do
    for ((j = 0; j < n-i-1; j++)); do
      if ! eval [[ "${dict[${keys[j]}]}" "$cmp_op" "${dict[${keys[j+1]}]}" ]]
      then
        # Swap the elements
        local temp="${keys[j]}"
        keys[j]="${keys[j+1]}"
        keys[j+1]="$temp"
      fi
    done
  done
}


