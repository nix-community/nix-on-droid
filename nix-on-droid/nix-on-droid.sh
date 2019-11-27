#!@bash@/bin/bash

PATH=@coreutils@/bin:@nix@/bin:${PATH:+:}$PATH

set -eu
set -o pipefail

function errorEcho() {
    >&2 echo $@
}

function doHelp() {
    echo "Usage: $0 [OPTION] COMMAND"
    echo
    echo "Options"
    echo
    echo "  -v|--verbose    Verbose output"
    echo "  -n|--dry-run    Do a dry run, only prints what actions would be taken"
    echo "  -h|--help       Print this help"
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
    echo "  help            Print this help"
    echo "  switch          Build and activate configuration"
}

function doSwitch() {
    local profileDirectory="/nix/var/nix/profiles/nix-on-droid"

    echo "Building activation package..."
    nix build \
        --no-link \
        --file "<nix-on-droid/modules>" \
        ${PASSTHROUGH_OPTS[*]} \
        activationPackage

    echo "Save profile activation package..."
    generationDir="$(nix path-info \
        --file "<nix-on-droid/modules>" \
        ${PASSTHROUGH_OPTS[*]} \
        activationPackage \
    )"
    nix-env --profile "${profileDirectory}" --set "${generationDir}"

    echo "Run activation script..."
    "${generationDir}/activate"
}


COMMAND=
PASSTHROUGH_OPTS=()

while [[ $# -gt 0 ]]; do
    opt="$1"
    shift
    case $opt in
        help|switch)
            COMMAND="$opt"
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
            errorEcho "$0: unknown option '$opt'"
            errorEcho "Run '$0 --help' for usage help"
            exit 1
            ;;
    esac
done

if [[ -z $COMMAND ]]; then
    doHelp >&2
    exit 1
fi

case $COMMAND in
    switch)
        doSwitch
        ;;
    help)
        doHelp
        ;;
    *)
        errorEcho "Unknown command: $COMMAND"
        doHelp >&2
        exit 1
        ;;
esac
