#!/usr/bin/env nix-shell
#! nix-shell -i bash -p bats ncurses

# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

set -ueo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROFILE_DIRECTORY="/nix/var/nix/profiles/nix-on-droid"

SELF_TEST_DIR="$HOME/.cache/nix-on-droid-self-test"
CONFIRMATION_FILE="$SELF_TEST_DIR/confirmation-granted"
DEFAULT_ACTIVATE_SCRIPT="$SELF_TEST_DIR/default-activate"
mkdir -p "$SELF_TEST_DIR"

if [[ ! -e "$CONFIRMATION_FILE" ]]; then
    echo 'These semi-automated tests are destructive!'
    echo 'They are meant to be executed by maintainers on a clean install.'
    echo 'Proceeding will wreck your installation.'
    echo 'Do you still wish to proceed?'
    echo -n '(type "I do" to proceed, anything else to abort) > '
    read -r CONFIRMATION
    if [[ "$CONFIRMATION" != 'I do' ]]; then echo 'Cool, aborting.'; exit 7; fi
    touch "$CONFIRMATION_FILE"
fi

if [[ ! -e "$DEFAULT_ACTIVATE_SCRIPT" ]]; then
    ln -sn "$(readlink -f "$PROFILE_DIRECTORY/activate")" "$DEFAULT_ACTIVATE_SCRIPT"
fi

_cleanup() {
    rm -rf ~/.config/nixpkgs
    mv ~/.config/nixpkgs.bak ~/.config/nixpkgs
}

trap _cleanup SIGINT SIGTERM SIGKILL

if [[ ! -d ~/.config/nixpkgs.bak ]]; then
    mv ~/.config/nixpkgs ~/.config/nixpkgs.bak
fi

mkdir -p ~/.config/nixpkgs

bats "${SCRIPT_DIR}" --verbose-run --timing --pretty "$@"

_cleanup
