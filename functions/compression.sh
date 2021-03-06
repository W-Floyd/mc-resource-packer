################################################################################
# Compression Functions
################################################################################

################################################################################
#
# __archive <OUTPUT> <FILE(s)>
#
# Archive
# Compresses named files and stores them in a file named according to <OUTPUT>
# Note that <OUTPUT> should not include a file extension. This extension is
# declared by the chosen routine, and stored in '__archive_extension'.
# Routines should check for, and remove, any conflicting files for themselves.
#
################################################################################

__archive() {

    __short_routine 'archive' 'archiving' 'zip ect gzip zopfli' "${@}"

    if ! [ -e "${1}.${__archive_extension}" ]; then
        __force_warn "File \"${1}.${__archive_extension}\" was not produced when archiving"
        return 1
    fi

}

################################################################################
# Zip
################################################################################

__routine__archive__zip() {

    __archive_extension='zip'

    local __dest="${1}.${__archive_extension}"

    if [ -e "${__dest}" ]; then
        rm "${__dest}"
    fi

    shift

    zip -q9 "${__dest}" "${@}"

}

################################################################################
# Gzip
################################################################################

__routine__archive__gzip() {

    local __ext_1='tar'
    local __ext_2='gz'

    __archive_extension="${__ext_1}.${__ext_2}"

    local __dest_1="${1}.${__ext_1}"
    local __dest_2="${1}.${__archive_extension}"

    if [ -e "${__dest_2}" ]; then
        rm "${__dest_2}"
    fi

    shift

    __tar "${__dest_1}" "${@}"

    gzip -9 "${__dest_1}"

}

################################################################################
# Zopfli
################################################################################

__routine__archive__zopfli() {

    local __ext_1='tar'
    local __ext_2='gz'

    __archive_extension="${__ext_1}.${__ext_2}"

    local __dest_1="${1}.${__ext_1}"
    local __dest_2="${1}.${__archive_extension}"

    if [ -e "${__dest_2}" ]; then
        rm "${__dest_2}"
    fi

    shift

    __tar "${__dest_1}" "${@}"

    zopfli "${__dest_1}"

    rm "${__dest_1}"

}

################################################################################
# ECT
################################################################################

__routine__archive__ect() {

    local __ext_1='tar'
    local __ext_2='gz'

    __archive_extension="${__ext_1}.${__ext_2}"

    local __dest_1="${1}.${__ext_1}"
    local __dest_2="${1}.${__archive_extension}"

    if [ -e "${__dest_2}" ]; then
        rm "${__dest_2}"
    fi

    shift

    __tar "${__dest_1}" "${@}"

    ect -quiet -gzip "${__dest_1}"

    rm "${__dest_1}"

}

################################################################################
# tar
################################################################################

__routine__archive__tar() {

    if ! [ -z "${__archive_extension}" ]; then

        local __archive_extension_1='tar'

    else

        __archive_extension='tar'
        local __archive_extension_1="${__archive_extension}"

    fi

    local __dest="${1}.${__archive_extension_1}"

    if [ -e "${__dest}" ]; then
        rm "${__dest}"
    fi

    shift

    __tar "${__dest}" "${@}"

}

################################################################################
#
# __tar <OUTPUT> <FILE(s)>
#
# Tar
# Collects named files and stores them in a file named according to <OUTPUT>
# Note that <OUTPUT> should not include a file extension.
#
################################################################################

__tar() {

    __short_routine 'tar' 'tarballing' 'tar' "${@}"

}

__routine__tar__tar() {

    tar -cf "${@}"

}

################################################################################
#
# __zip <OUTPUT>
#
# Zip
# To be run from within a folder, it zips all contents into a file in the parent
# directory. __archive will more commonly be used, this is reserved for zipping
# base level files for Minecraft itself. <OUTPUT> should not contain the '.zip'
# extension, though that extension should be assumed elsewhere.
#
################################################################################

__zip() {

    __short_routine 'zip' 'zipping' 'zip' "${1}"

    if ! [ -e "../${1}.zip" ]; then
        __force_warn "File \"${1}.zip\" was not produced when zipping"
        return 1
    fi

}

################################################################################
# Zip
################################################################################

__routine__zip__zip() {

    if [ "${__compress}" = '1' ]; then

        zip -q -9 -r "../${1}.zip" ./

    else

        zip -qZ store -r "../${1}.zip" ./

    fi

}
