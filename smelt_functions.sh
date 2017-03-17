###############################################################
# Functions
###############################################################
#
# __mext <string>
#
# Minus Extension
# Strips last file extension from string
#
###############################################################

__mext () {
sed 's|\(.*\)\(\.\).*|\1|' <<< "${1}"
}

###############################################################
#
# __oext <string>
#
# Only Extension
# Returns the final extension of a filename
# Opposite of __mext
#
###############################################################

__oext () {
sed 's|\(.*\)\(\.\)\(.*\)|\3|' <<< "${1}"
}

###############################################################
#
# __lsdir <DIR>
#
# List directories
# Lists all directories in the current folder, or specified
# folder
#
###############################################################

__lsdir () {
if [ -z "${1}" ]; then
    find . -maxdepth 1 -mindepth 1 -type d | sort
else
    find "${1}" -maxdepth 1 -mindepth 1 -type d | sort
fi
}

###############################################################
# XML Functions
###############################################################
#
# __get_range <FILE> <FIELD_NAME>
#
# Get Range
# Gets the range/s in a <FILE> between each set of <FIELD_NAME>
#
# When piped version is used, FILE should be omitted
#
# Example:
#
# __get_range catalogue.xml ITEM
#
# will print
#
# 2,10
# 11,19
# 20,28
# 31,39
#
###############################################################

__get_range () {
grep -n '[</|<]'"${2}"'>' < "${1}" | sed 's/\:.*//' |  sed 'N;s/\n/,/'
}

__get_range_piped () {
cat | grep -n '[</|<]'"${1}"'>' | sed 's/\:.*//' |  sed 'N;s/\n/,/'
}

###############################################################
#
# __read_range <FILE> <RANGE>
#
# Read Range
# Reads the <RANGE> from a <FILE>, as generated by __get_range
# Must be single line input.
#
# When piped version is used, FILE should be omitted
#
###############################################################

__read_range () {
sed -e "${2}"'!d' -e 's/^[\t| ]*//' "${1}"
}

__read_range_piped () {
cat | sed -e "${1}"'!d' -e 's/^[\t| ]*//'
}

###############################################################
#
# __get_value/s <DATASET> <FIELD_NAME1> <FIELD_NAME2> ...
#
# Get Value
# Gets the value/s of <FIELD_NAME> from <DATASET>
# Meant to be used on separated data-sets.
#
# When piped version is used, DATASET should be omitted
#
# When __get_values* is used, multiple field names may be
# specified
#
# When test variants are used, only fields that exist are
# pulled, non-existant ones fail silently
#
###############################################################

###############################################################
#
# __field_default <DATASET> <FIELD_NAME>
#
# Returns the default value for a field, given the context of a
# provided DATASET.
#
# piped should pipe in DATASET
#
###############################################################

__field_default () {
cat "${1}" | __field_default_piped "${2}"
}

__field_default_piped () {
local __pipe="$(cat)"
case "${1}" in

    "IMAGE")
        if [ "$(__oext "$(__get_value_piped NAME <<< "${__pipe}")")" = 'png' ]; then
            echo YES
        else
            echo NO
        fi
        ;;
    "KEEP" | "OPTIONAL")
        echo "NO"
        ;;
esac
}

###############################################################

__get_value () {
pcregrep -M -o1 "<${2}>((\n|.)*)</${2}>" "${1}"
}

__get_value_test () {
if __test_field "${1}" "${2}"; then
    pcregrep -M -o1 "<${2}>((\n|.)*)</${2}>" "${1}"
else
    __field_default "${1}" "${2}"
fi
}

__get_value_piped () {
cat | pcregrep -M -o1 "<${1}>((\n|.)*)</${1}>"
}

__get_value_piped_test () {
local __pipe="$(cat)"
if __test_field_piped "${1}" <<< "${__pipe}"; then
    pcregrep -M -o1 "<${1}>((\n|.)*)</${1}>" <<< "${__pipe}"
else
    __field_default_piped "${1}" <<< "${__pipe}"
fi
}

__get_values () {
local __file="${1}"
shift
for __input in "$@"; do
    pcregrep -M -o1 "<${1}>((\n|.)*)</${1}>" "${__file}"
    shift
done
}

__get_values_test () {
local __file="${1}"
shift
for __input in "$@"; do
    if __test_field "${__file}" "${1}"; then
        pcregrep -M -o1 "<${1}>((\n|.)*)</${1}>" "${__file}"
    else
        __field_default "${__file}" "${1}"
    fi
    shift
done
}

__get_values_piped () {
local __pipe="$(cat)"
for __input in "$@"; do
    pcregrep -M -o1 "<${1}>((\n|.)*)</${1}>" <<< "${__pipe}"
    shift
done
}

__get_values_piped_test () {
local __pipe="$(cat)"
for __input in "$@"; do
    if __test_field_piped "${1}" <<< "${__pipe}"; then
        pcregrep -M -o1 "<${1}>((\n|.)*)</${1}>" <<< "${__pipe}"
    else
        __field_default_piped "${1}" <<< "${__pipe}"
    fi
    shift
done
}

###############################################################
#
# __set_value <DATASET> <FIELD_NAME> <VALUE>
#
# Set Value
# Sets the <VALUE> of the specified <FIELD_NAME>
#
# When piped version is used, VALUE should be omitted
#
# When test variants are used, fields are created when needed
#
# Add value assumes the value is missing, unless check is used
#
###############################################################

__add_value () {
echo "<${2}>${3}</${2}>" >> "${1}"
}

__add_value_test () {
if ! __test_field "${1}" "${2}"; then
    __add_value "${1}" "${2}" "${3}"
fi
}

__set_value () {
perl -i -pe "BEGIN{undef $/;} s#<${2}>.*</${2}>#<${2}>${3}</${2}>#sm" "${1}"
}

__set_value_piped () {
perl -i -pe "BEGIN{undef $/;} s#<${2}>.*</${2}>#<${2}>$(cat)</${2}>#sm" "${1}"
}

__set_value_test () {
if ! __test_field "${1}" "${2}"; then
    echo "<${2}></${2}>" >> "${1}"
fi
perl -i -pe "BEGIN{undef $/;} s#<${2}>.*</${2}>#<${2}>${3}</${2}>#sm" "${1}"
}

__set_value_piped_test () {
if ! __test_field "${1}" "${2}"; then
    echo "<${2}></${2}>" >> "${1}"
fi
perl -i -pe "BEGIN{undef $/;} s#<${2}>.*</${2}>#<${2}>$(cat)</${2}>#sm" "${1}"
}

###############################################################
#
# __test_field <DATASET> <FIELD>
#
# Test Field
# Tests if a field exists in a dataset. Returns 0 if it exists,
# 1 if it does not.
#
###############################################################

__test_field () {
if grep -q "^<${2}>" "${1}"; then
    return 0
else
    return 1
fi
}

__test_field_piped () {
if grep -q "^<${1}>" <<< "$(cat)"; then
    return 0
else
    return 1
fi
}

###############################################################
#
# __list_optional_fields
#
# List Optional Fields
# Lists all optional fields
#
###############################################################

__list_optional_fields () {
echo "CONFIG
SIZE
OPTIONS
KEEP
IMAGE
DEPENDS
CLEANUP
OPTIONAL
COMMON"
}

__list_required_fields () {
echo "NAME"
}

__list_all_fields () {
{
__list_optional_fields
__list_required_fields
} | sort
}

###############################################################
# Other stuff
###############################################################
#
# __emergency_exit
#
# Prints the last known command and exits, to be used when a
# command fails
#
# Example:
# cd "${__dir}" || __emergency_exit
#
###############################################################

__emergency_exit () {
echo "Last command run was ["!!"]"
exit 1
}

###############################################################
#
# __hash_folder <FILE> <EXCLUDEDIR>
#
# Hashes the current folder and outputs to <FILE>
# EXCLUDEDIR is optional (in the form of "xml", not "./xml/")
#
###############################################################

__hash_folder () {
if [ -z "${2}" ]; then
local __listing="$(find . -type f)"
else
local __listing="$(find . -not -path "./${2}/*" -type f)"
fi
if ! [ -z "${__listing}" ]; then
    md5sum ${__listing} > "${1}"
fi
}

###############################################################
#
# __check_hash_folder <FILE> <OUTPUT>
#
# Hashes the current folder and compares to <FILE>, outputting
# to <OUTPUT>
#
###############################################################

__check_hash_folder () {
md5sum -c "${1}" > "${2}"
}

###############################################################
#
# __pushd <DIR>
#
# Same as regular pushd, just quiet unless told not to be
#
###############################################################

__pushd () {
if [ -d "${1}" ]; then
    pushd "${1}" 1> /dev/null
else
    echo "Directory \"${1}\" does not exist!"
    exit 2
fi
}

###############################################################
#
# __popd
#
# Same as regular popd, just quiet unless told not to be
#
###############################################################

__popd () {
popd 1> /dev/null
}

###############################################################
#
# __strip_ansi
#
# Strips ANSI codes from *piped* input
#
###############################################################

__strip_ansi () {
cat | perl -pe 's/\e\[?.*?[\@-~]//g'
}

###############################################################
#
# ... | __stdconf
#
# Replaces %stdconf% with the appropriate pointer
#
###############################################################

__stdconf () {
cat | sed "s#%stdconf%#${__standard_conf_dir}#g"
}

###############################################################
#
# __print_pad
#
# Prints the given number of spaces
#
###############################################################

__print_pad () {
    seq 1 "${1}" | while read -r __line; do
        echo -n ' '
    done
}

###############################################################
#
# __format_text <LEADER> <TEXT> <TRAILER>
#
# Pads text to a set length, so multiline warnings, info and
# errors can be made
###############################################################

__format_text () {
echo -ne "${1}"
local __desired_size='7'
local __leader_size="$(echo -ne "${1}" | __strip_ansi | wc -m)"
local __clipped_size=$((__desired_size-__leader_size-3))
local __front_pad="$(__print_pad "${__clipped_size}") - "
echo -ne "${__front_pad}"
local __pad=''
if [ "$(echo "${2}" | wc -l)" -gt '1' ]; then
    echo "${2}" | head -n -1 | while read -r __line; do
        if [ -z "${__pad}" ]; then
            echo -e "${__pad}${__line}"
            local __pad="$(__print_pad "${__desired_size}")"
        else
            echo -e "${__pad}${__line}"
        fi
    done
    local __pad="$(__print_pad "${__desired_size}")"
    echo -e "${__pad}$(echo "${2}" | tail -n 1)${3}"
else
    echo -e "${2}${3}"
fi
}

###############################################################
#
# __bypass_announce <MESSAGE>
#
# Bypass Announce
# Echos a statement no matter what
#
###############################################################

__bypass_announce () {
__format_text "\e[32mINFO\e[39m" "${1}" ""
}

###############################################################
#
# __force_announce <MESSAGE>
#
# Force Announce
# Echos a statement, when __quiet is equal to 0
#
###############################################################

__force_announce () {
if [ "${__quiet}" = '0' ]; then
    __bypass_announce "${1}"
fi
}

###############################################################
#
# __announce <MESSAGE>
#
# Announce
# Echos a statement, only if __verbose is equal to 1
#
###############################################################

__announce () {
if [ "${__time}" = '0' ] && [ "${__verbose}" = '1' ] && ! [ "${__name_only}" = '1' ] && ! [ "${__list_changed}" = '1' ]; then
    __force_announce "${1}"
fi
}

###############################################################
#
# __force_warn <MESSAGE>
#
# Warn
# Echos a statement when something has gone wrong
#
###############################################################

__force_warn () {
if ! [ "${__name_only}" = '1' ] && ! [ "${__list_changed}" = '1' ]; then
    __format_text "\e[93mWARN\e[39m" "${1}" ", continuing anyway." 1>&2
fi
}

###############################################################
#
# __warn <MESSAGE>
#
# Warn
# Echos a statement when something has gone wrong, to be used
# when it is tolerable.
#
###############################################################

__warn () {
if [ "${__very_verbose}" = '1' ] || [ "${__should_warn}" = '1' ]; then
if ! [ "${__name_only}" = '1' ] && ! [ "${__list_changed}" = '1' ]; then
    __force_warn "${@}"
fi
fi
}

###############################################################
#
# __custom_error <MESSAGE>
#
# Custom Error
# Echos an error statement without quiting
#
###############################################################

__custom_error () {
__format_text "\e[31mERRO\e[39m" "${1}" "${2}" 1>&2
}

###############################################################
#
# __error <MESSAGE>
#
# Error
# Echos a statement when something has gone wrong, then exits
#
###############################################################

__error () {
__custom_error "${1}" ", exiting."
exit 1
}

###############################################################
#
# __force_time <MESSAGE> <start/end>
#
# Force Time
# Times between two occurrences of the function, as set by start
# or end, only if time is on.
#
###############################################################

__force_time () {
local __message="$(echo "${1}" | md5sum | sed 's/ .*//')"

if [ -z "${2}" ] || [ -z "${1}" ]; then
    __force_warn "Missing option in time function."
else

if [ "${2}" = 'start' ]; then
    export "__function_start_time${__message}"="$(date +%s.%N)"
elif [ "${2}" = 'end' ]; then
    export "__function_end_time${__message}"="$(date +%s.%N)"
fi

if ! [ "${__name_only}" = '1' ] && [ "${__time}" = '1' ] && ! [ "${__list_changed}" = '1' ]; then
    if [ -z "${2}" ]; then
        __force_warn "No input to __time function, disabling timer."
        __time='0'
    else

        if [ "${2}" = 'end' ]; then
            __format_text "\e[32mTIME\e[39m" "${1} in $(echo "$(eval 'echo '"\$__function_end_time${__message}"'')-$(eval 'echo '"\$__function_start_time${__message}"'')" | bc) seconds" ""
        elif ! [ "${2}" = 'start' ]; then
            __force_warn "Invalid input to __time, '${2}'"
        fi

    fi
fi

fi
}

###############################################################
#
# __time <MESSAGE> <start/end>
#
# Time
# Times between two occurrences of the function, as set by start
# or end, only if verbose is on.
#
###############################################################

__time () {
if [ "${__verbose}" = '1' ]; then
    __force_time "${1}" "${2}"
fi
}

###############################################################
#
# __log2 <NUMBER>
#
# Log base 2
# Finds the log2 of a number, or rounds up to the next power of
# 2
#
# Shamelessly stolen from:
# https://bobcopeland.com/blog/2010/09/log2-in-bash/
#
###############################################################

__log2 () {
local x=0
for (( y=$1-1 ; $y > 0; y >>= 1 )) ; do
    let x=$x+1
done
echo $x
}

###############################################################
#
# ... | __strip_zero
#
# Strip Zero
# From pipe, strips trailing zeros and dangling decimal place
#
###############################################################

__strip_zero () {
cat | sed -e 's/\([^0]*\)0*$/\1/' -e 's/\.$//'
}

###############################################################
#
# ... | __clean_pack
#
# Clean Pack
# From pipe, strips leading spaces and tabs, deletes lines that
# then start with a # after leaders have been stripped
#
###############################################################

__clean_pack () {
cat | sed -e 's/^[ |\t]*//' -e '/^#/d' | sed '/^$/d' | __stdconf
}

###############################################################
#
# __check_optimizer <OPTIMIZER>
#
# Check Optimizer
# Checks that an optimizer exists, and an appropriate function
# for it exists. Returns 0 on success, 1 on failure
#
###############################################################

__check_optimizer () {
if which "${1}" &> /dev/null && [ "$(type -t "__optimize_${1}")" = 'function' ]; then
    return 0
else
    return 1
fi
}

###############################################################
#
# __list_optimizers
#
# List Optimizers
# Lists optimizers that exist, both custom and standard
#
###############################################################

__list_optimizers () {
compgen -A function | grep '^__optimize_' | sort | sed 's/__optimize_//'
}

###############################################################
# Export functions
###############################################################
#
# Do this so that any child shells have these functions
###############################################################
for __function in $(compgen -A function); do
	export -f ${__function}
done
