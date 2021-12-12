#!/usr/bin/env nix-shell
#! nix-shell -i bash -p bats ncurses

# Copyright (c) 2019-2021, see AUTHORS. Licensed under MIT License, see LICENSE.

set -ueo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
SELF_TEST_DIR="$HOME/.cache/nix-on-droid-self-test"
CONFIRMATION_FILE="$SELF_TEST_DIR/confirmation-granted"
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

if [[ ! -d ~/.config.bak ]]; then
    mv ~/.config ~/.config.bak
    cp -r ~/.config.bak ~/.config
fi

bats "${SCRIPT_DIR}" --verbose-run --timing --pretty

rm -rf ~/.config
mv ~/.config.bak ~/.config
