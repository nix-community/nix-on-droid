#!@bash@/bin/bash

# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

PATH=@coreutils@/bin:@nix@/bin:${PATH:+:}$PATH

set -eu
set -o pipefail

PROFILE_DIRECTORY="/nix/var/nix/profiles/nix-on-droid"

function errorEcho() {
    >&2 echo "$@"
}

function setupPasstroughOpts() {
    if [[ -v VERBOSE ]]; then
        PASSTHROUGH_OPTS+=(--show-trace)
    fi

    if [[ -n "$CONFIG_FILE" ]]; then
        PASSTHROUGH_OPTS+=(--argstr config "$(realpath "$CONFIG_FILE")")
    fi
}

function nixActivationPackage() {
    local command="$1"
    local extraArgs=("${@:2}"
                     --extra-experimental-features nix-command
                     "${PASSTHROUGH_OPTS[@]}")
    if [[ -n "${FLAKE_CONFIG_URI}" ]]; then
        extraArgs+=(--impure "${FLAKE_CONFIG_URI}.activationPackage")
    else
        extraArgs+=(--file "<nix-on-droid/modules>" activationPackage)
    fi

    nix "${command}" "${extraArgs[@]}"
}


function doBuild() {
    echo "Building activation package..."
    nixActivationPackage build
}

function doGenerations() {
    nix-env --profile $PROFILE_DIRECTORY --list-generations
}

function doHelp() {
    echo "Usage: $0 [OPTION] COMMAND"
    echo
    echo "Options"
    echo
    echo "  -h|--help         Print this help"
    echo "  -n|--dry-run      Do a dry run, only prints what actions would be taken"
    echo "  -v|--verbose      Verbose output"
    echo "  -f|--file FILE    Path to config file"
    echo "  -F|--flake FLAKE  Path to flake and device name (e.g. path/to/flake#device),"
    echo "                    device 'default' will be used if no attribute name is given"
    echo
    echo "Options passed on to nix build"
    echo
    echo "  -I|--include PATH"
    echo "  --builders BUILDERS"
    echo "  --cores NUM"
    echo "  --keep-failed"
    echo "  --keep-going"
    echo "  --max-jobs NUM"
    echo "  --option NAME VALUE"
    echo "  --override-input INPUT URL"
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
    echo "  build           Build configuration"
    echo
    echo "  switch          Build and activate configuration"
    echo
    echo "  switch-generation NUM"
    echo "                  Switch generation and activate configuration"
}

function doOnDeviceTest() {
    nix-channel --update nix-on-droid
    exec "$(nix-instantiate --eval --expr \
                            "<nix-on-droid/tests/on-device/.run.sh>")" "$@"
}

function doSwitch() {
    if [[ -e "$HOME/.config/nix-on-droid/flake.nix" && -z "${FLAKE_CONFIG_URI}" ]]; then
        echo -n '~/.config/nix-on-droid/flake.nix exists, '
        echo -n "you might've intended to run "
        echo '`nix-on-droid switch --flake ~/.config/nix-on-droid`'
    fi

    echo "Building activation package..."
    nixActivationPackage build --no-link

    echo "Executing activation script..."
    generationDir="$(nixActivationPackage path-info)"

    "${generationDir}/activate"
}

function doSwitchGeneration() {
    local generationNum=$1

    if [[ -x "${PROFILE_DIRECTORY}-${generationNum}-link/activate" ]]; then
        echo "Executing activation script..."
        "${PROFILE_DIRECTORY}-${generationNum}-link/activate"
    else
        errorEcho "Activation was not successful, generation is either broken or already garbage collected."
        errorEcho "See 'nix-on-droid generations' for available generations."
        exit 1
    fi
}


COMMAND_ARGS=()
COMMAND=
CONFIG_FILE=
FLAKE_CONFIG_URI=
PASSTHROUGH_OPTS=()

while [[ $# -gt 0 ]]; do
    opt="$1"
    shift
    case $opt in
        build|generations|help|rollback|switch|switch-generation|on-device-test)
            COMMAND="$opt"
            ;;
        -f|--file)
            CONFIG_FILE="$1"
            shift
            ;;
        -F|--flake)
            PASSTHROUGH_OPTS+=(--extra-experimental-features "flakes nix-command")
            # add "nixOnDroidConfigurations." as prefix in attribute name, e.g.
            # /path/to/flake#device -> /path/to/flake#nixOnDroidConfigurations.device
            # if no attribute name given, use "default"
            if [[ "$1" =~ \# ]]; then
                FLAKE_CONFIG_URI="${1%#*}#nixOnDroidConfigurations.${1#*#}"
            else
                FLAKE_CONFIG_URI="${1}#nixOnDroidConfigurations.default"
            fi
            shift
            ;;
        -h|--help)
            doHelp
            exit 0
            ;;
        -I|--include)
            PASSTHROUGH_OPTS+=(-I "$1")
            shift
            ;;
        -n|--dry-run)
            export DRY_RUN=1
            ;;
        --option|--override-input)
            PASSTHROUGH_OPTS+=("$opt" "$1" "$2")
            shift 2
            ;;
        --builders|--cores|--max-jobs)
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
                    switch-generation|on-device-test)
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

setupPasstroughOpts

if [[ -z $COMMAND ]]; then
    doHelp >&2
    exit 1
fi

case $COMMAND in
    build)
        doBuild
        ;;
    generations)
        doGenerations
        ;;
    help)
        doHelp
        ;;
    on-device-test)
        doOnDeviceTest "${COMMAND_ARGS[@]}"
        ;;
    rollback)
        if [[ $(readlink $PROFILE_DIRECTORY) =~ ^nix-on-droid-([0-9]+)-link$ ]]; then
            doSwitchGeneration $((BASH_REMATCH[1] - 1))
        else
            errorEcho "Nix-on-Droid profile link is broken, please run 'nix-on-droid switch' to fix it."
            exit 1
        fi
        ;;
    switch)
        doSwitch
        ;;
    switch-generation)
        if [[ ${#COMMAND_ARGS[@]} -eq 1 ]]; then
            doSwitchGeneration "${COMMAND_ARGS[0]}"
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
