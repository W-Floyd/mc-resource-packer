################################################################################
# Message Functions
################################################################################

################################################################################
#
# __strip_ansi
#
# Strips ANSI codes from *piped* input.
#
################################################################################

__strip_ansi () {
cat | perl -pe 's/\e\[?.*?[\@-~]//g'
}

################################################################################
#
# __print_pad
#
# Prints the given number of spaces.
#
################################################################################

__print_pad () {
local i='0'
until [ "${i}" = "${1}" ]; do
    echo -n ' '
    i=$((i+1))
done
}

################################################################################
#
# __format_text <LEADER> <TEXT> <TRAILER>
#
# Pads text to a set length, so multiline warnings, info and errors can be made.
#
################################################################################

__format_text () {
echo -ne "${1}"
local __desired_size='7'
local __leader_size="$(echo -ne "${1}" | __strip_ansi | wc -m)"
local __clipped_size=$((__desired_size-__leader_size-3))
local __front_pad="$(__print_pad "${__clipped_size}") - "
echo -ne "${__front_pad}"
local __pad=''

if [ "$(wc -l <<< "${2}")" -gt '1' ]; then
    head -n -1 <<< "${2}" | while read -r __line; do
        if [ -z "${__pad}" ]; then
            echo -e "${__pad}${__line}"
            local __pad="$(__print_pad "${__desired_size}")"
        else
            echo -e "${__pad}${__line}"
        fi
    done
    local __pad="$(__print_pad "${__desired_size}")"
    echo -e "${__pad}$(tail -n 1 <<< "${2}")${3}"
else
    echo -e "${2}${3}"
fi

}

################################################################################
#
# __bypass_announce <MESSAGE>
#
# Bypass Announce
# Echos a statement no matter what.
#
################################################################################

__bypass_announce () {
__format_text "\e[32mINFO\e[39m" "${1}" ""
}

################################################################################
#
# __force_announce <MESSAGE>
#
# Force Announce
# Echos a statement, when __quiet is equal to 0.
#
################################################################################

__force_announce () {
if [ "${__quiet}" = '0' ]; then
    __bypass_announce "${1}"
fi
}

################################################################################
#
# __announce <MESSAGE>
#
# Announce
# Echos a statement, only if __verbose is equal to 1.
#
################################################################################

__announce () {
if [ "${__time}" = '0' ] && [ "${__verbose}" = '1' ] && ! [ "${__name_only}" = '1' ] && ! [ "${__list_changed}" = '1' ]; then
    __force_announce "${1}"
fi
}

################################################################################
#
# __force_warn <MESSAGE>
#
# Warn
# Echos a statement when something has gone wrong.
#
################################################################################

__force_warn () {
if ! [ "${__name_only}" = '1' ] && ! [ "${__list_changed}" = '1' ]; then
    __format_text "\e[93mWARN\e[39m" "${1}" ", continuing anyway." 1>&2
fi
}

################################################################################
#
# __warn <MESSAGE>
#
# Warn
# Echos a statement when something has gone wrong, to be used when it is
# tolerable.
#
################################################################################

__warn () {
if [ "${__very_verbose}" = '1' ] || [ "${__should_warn}" = '1' ]; then
if ! [ "${__name_only}" = '1' ] && ! [ "${__list_changed}" = '1' ]; then
    __force_warn "${@}"
fi
fi
}

################################################################################
#
# __custom_error <MESSAGE>
#
# Custom Error
# Echos an error statement without quiting.
#
################################################################################

__custom_error () {
__format_text "\e[31mERRO\e[39m" "${1}" "${2}" 1>&2
}

################################################################################
#
# __error <MESSAGE>
#
# Error
# Echos a statement when something has gone wrong, then exits.
#
################################################################################

__error () {
__custom_error "${1}" ", exiting."
exit 1
}

################################################################################
#
# __fold <LINE> <PAD_NUM>
#
# Fold
# Folds the line, with second option being the number of spaces to pad other
# lines with. If that number is not specified, no padding is added (like '0').
#
################################################################################

__fold () {
    local max_length=78
    if ! [ "${#1}" -gt "${max_length}" ]; then
        printf -- "${1}\n"
    else
        if ! shopt -q -p extglob; then
            local start_glob='0'
            shopt -s extglob
        else
            local start_glob='1'
        fi
        local __word
        local tmp_cur_line
        if [ -z "${2}" ]; then
            local pad=''
        else
            local pad="$(__print_pad "${2}")"
        fi

	    local cur_line=''
	    local i=0
        local input="${1}"
	    local leading_space="${input//[^ ]*}"
        while IFS= read -d ' ' -r __word; do
            if [ "${i}" = '0' ]; then
                tmp_cur_line="${__word}"
            else
                tmp_cur_line="${cur_line} ${__word}"
            fi

            if ! [ "${#tmp_cur_line}" -gt "${max_length}" ]; then
                if [ "${i}" = '0' ]; then
                    cur_line="${__word}"
                else
                    cur_line="${cur_line} ${__word}"
                fi
            else
                printf -- "${cur_line}\n"
                cur_line="${pad}${__word}"
            fi
            i=$((i+1))
        done <<< "${input} "
        printf -- "${cur_line}\n"
        if [ "${start_glob}" = '0' ]; then
            shopt -u extglob
        fi
    fi
}

################################################################################
#
# ... | __help_fold
#
# Help Fold
# Fold help messages, with special formatting catches.
# If a line starts with '@', it should be treated like an option line, if '%',
# then no padding, like a text line. If neither, guess.
#
################################################################################
__help_fold () {
while IFS= read -r __line; do
    case "${__line}" in
        @*)
            __fold "${__line#@}" 28
            ;;
        %*)
            __fold "${__line#%}"
            ;;
        *)
            if grep -qE '^ *-' <<< "${__line}"; then
                __fold "${__line}" 28
            else
                __fold "${__line}"
            fi
            ;;
    esac

done
}
