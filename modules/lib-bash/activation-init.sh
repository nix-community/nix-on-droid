if [[ -v VERBOSE ]]; then
    export VERBOSE_ECHO=echo
    export VERBOSE_ARG="--verbose"
else
    export VERBOSE_ECHO=true
    export VERBOSE_ARG=""
fi

if [[ -v DRY_RUN ]] ; then
    echo "This is a dry run"
    export DRY_RUN_CMD=echo
else
    $VERBOSE_ECHO "This is a live run"
    export DRY_RUN_CMD=""
fi

if [[ -v VERBOSE ]]; then
    echo -n "Using Nix version: "
    nix --version
fi
