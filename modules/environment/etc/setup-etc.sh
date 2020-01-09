# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

# Inspired by
# https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/etc/setup-etc.pl
# (Copyright (c) 2003-2019 Eelco Dolstra and the Nixpkgs/NixOS contributors,
#  licensed under MIT License as well)


set -eu -o pipefail

: "${VERBOSE_ARG:=}"
: "${VERBOSE_ECHO:=true}"

etc="${1}"
static="/etc/static"
new_etc="${2}"
backup_extension="${3:-}"

function atomic_symlink() {
    local source="${1}"
    local target="${2}"
    local target_tmp="${target}.tmp"

    $VERBOSE_ECHO "Atomic symlink ${source} to ${target}..."

    mkdir -p "$(dirname "${target_tmp}")"
    ln -sf "${source}" "${target_tmp}"
    mv -T "${target_tmp}" "${target}"
}

# Remove dangling symlinks that point to /etc/static.  These are
# configuration files that existed in a previous configuration but not
# in the current one.
function cleanup() {
    local file
    for file in $(find "${etc}/" -xtype l); do
        local target="$(readlink "${file}")"
        if [[ ! -L "${target}" ]]; then
            echo "Removing obsolete symlink '${file}'..."
            rm "${file}"
        fi
    done
}

# Returns 0 if the argument points to the files in /etc/static.  That
# means either argument is a symlink to a file in /etc/static or a
# directory with all children being static.
function is_static() {
    local path="${1}"

    if [[ -L "${path}" ]]; then
        [[ "$(readlink "${path}")" == ${static}/* ]]
        return
    fi

    if [[ -d "${path}" ]]; then
        local file
        for file in "${path}"/*; do
            is_static "${file}" || return
        done
    fi

    false
}

function link() {
    if [[ ! -d "${new_etc}" ]]; then
        return
    fi

    local name
    for name in $(find "${new_etc}/" -type l | sed -e "s,^${new_etc}/,,"); do
        local target="${etc}/${name}"

        mkdir $VERBOSE_ARG -p "$(dirname "${target}")"

        if [[ -e "${target}" ]] && ! is_static "${target}"; then
            if [[ -n "${backup_extension}" ]]; then
                echo "Backing up '${target}' to '${target}${backup_extension}'..."
                cp "${target}" "${target}${backup_extension}"

                atomic_symlink "${static}/${name}" "${target}"
            else
                echo "Linking of ${target} failed. Please remove this file."
            fi
        else
            atomic_symlink "${static}/${name}" "${target}"
        fi
    done
}

# On initial build /etc/static is a directory instead of a symlink
if [[ -e "${etc}/static" && ! -L "${etc}/static" ]]; then
    rm $VERBOSE_ARG --recursive "${etc}/static"
fi

# Atomically update /etc/static to point at the etc files of the
# current configuration.
atomic_symlink "${new_etc}" "${etc}/static"

cleanup

link
