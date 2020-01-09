#!@bash@/bin/bash

# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

PATH=@coreutils@/bin:@nix@/bin:${PATH:+:}$PATH

set -eu
set -o pipefail

PROFILE_DIRECTORY="/nix/var/nix/profiles/nix-on-droid"

function errorEcho() {
    >&2 echo $@
}

function doGenerations() {
    nix-env --profile $PROFILE_DIRECTORY --list-generations
}

function doHelp() {
    echo "Usage: $0 [OPTION] COMMAND"
    echo
    echo "Options"
    echo
    echo "  -h|--help       Print this help"
    echo "  -n|--dry-run    Do a dry run, only prints what actions would be taken"
    echo "  -v|--verbose    Verbose output"
    echo "  -f|--file       Path to config file"
    echo
    echo "Options passed on to nix build"
    echo
    echo "  --cores NUM"
    echo "  --keep-failed"
    echo "  --keep-going"
    echo "  --max-jobs NUM"
    echo "  --option NAME VALUE"
    echo "  --show-trace"
    echo
    echo "Commands"
    echo
    echo "  generations     Show all generations"
    echo
    echo "  help            Print this help"
    echo
    echo "  rollback        Rollback and activate configuration"
    echo
    echo "  switch          Build and activate configuration"
    echo
    echo "  switch-generation NUM"
    echo "                  Switch generation and activate configuration"
}

function doSwitch() {
    if [[ -v VERBOSE ]]; then
        PASSTHROUGH_OPTS+=(--show-trace)
    fi

    if [[ -n "$CONFIG_FILE" ]]; then
        PASSTHROUGH_OPTS+=(--argstr config "$(realpath "$CONFIG_FILE")")
    fi

    echo "Building activation package..."
    nix build \
        --no-link \
        --file "<nix-on-droid/modules>" \
        ${PASSTHROUGH_OPTS[*]} \
        activationPackage

    echo "Executing activation script..."
    generationDir="$(nix path-info \
        --file "<nix-on-droid/modules>" \
        ${PASSTHROUGH_OPTS[*]} \
        activationPackage \
    )"

    "${generationDir}/activate"
}

function doSwitchGeneration() {
    local generationNum=$1

    if [[ -x "${PROFILE_DIRECTORY}-${generationNum}-link/activate" ]]; then
        echo "Executing activation script..."
        "${PROFILE_DIRECTORY}-${generationNum}-link/activate"
    else
        errorEcho "Activation was not successful, generation is either broken or already garbage collected."
        errorEcho "See nix-on-droid generations for available generations."
        exit 1
    fi
}


COMMAND=
COMMAND_ARGS=()
PASSTHROUGH_OPTS=()
CONFIG_FILE=

while [[ $# -gt 0 ]]; do
    opt="$1"
    shift
    case $opt in
        generations|help|rollback|switch|switch-generation)
            COMMAND="$opt"
            ;;
        -f|--file)
            CONFIG_FILE="$1"
            shift
            ;;
        -h|--help)
            doHelp
            exit 0
            ;;
        -n|--dry-run)
            export DRY_RUN=1
            ;;
        --option)
            PASSTHROUGH_OPTS+=("$opt" "$1" "$2")
            shift 2
            ;;
        --max-jobs|--cores)
            PASSTHROUGH_OPTS+=("$opt" "$1")
            shift
            ;;
        --keep-failed|--keep-going|--show-trace)
            PASSTHROUGH_OPTS+=("$opt")
            ;;
        -v|--verbose)
            export VERBOSE=1
            ;;
            *)
                case $COMMAND in
                    switch-generation)
                        COMMAND_ARGS+=("$opt")
                        ;;
                    *)
                        errorEcho "$0: unknown option '$opt'"
                        errorEcho "Run '$0 --help' for usage help"
                        exit 1
                        ;;
                esac
            ;;
    esac
done

if [[ -z $COMMAND ]]; then
    doHelp >&2
    exit 1
fi

case $COMMAND in
    generations)
        doGenerations
        ;;
    help)
        doHelp
        ;;
    rollback)
        if [[ $(readlink $PROFILE_DIRECTORY) =~ ^nix-on-droid-([0-9]+)-link$ ]]; then
            doSwitchGeneration $((${BASH_REMATCH[1]} - 1))
        else
            errorEcho "nix-on-droid profile link is broken, please run nix-on-droid switch to fix it."
            exit 1
        fi
        ;;
    switch)
        doSwitch
        ;;
    switch-generation)
        if [[ ${#COMMAND_ARGS[@]} -eq 1 ]]; then
            doSwitchGeneration ${COMMAND_ARGS[0]}
        else
            errorEcho "switch-generation expects one argument, got ${#COMMAND_ARGS[@]}."
            exit 1
        fi
        ;;
    *)
        errorEcho "Unknown command: $COMMAND"
        doHelp >&2
        exit 1
        ;;
esac
