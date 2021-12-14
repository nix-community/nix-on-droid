#!/usr/bin/env bash

# This is a script to run "on-device" tests in CI, without the device.
# Takes the bootstrap aarch64 zipball, unpacks, proots into it.
# This won't catch all bugs, of course, but that's something.

# Set up envvars, prepare directories:

set -ueo pipefail

QEMU_URL=https://github.com/multiarch/qemu-user-static/releases/download/v6.1.0-8/qemu-aarch64-static
QEMU=.fakedroid/inj/qemu-aarch64
INSTALLATION_DIR=/data/data/com.termux.nix/files/usr
TARGET_HOME=/data/data/com.termux.nix/files/home

mkdir -p .fakedroid/inj
mkdir -p .fakedroid/env/{$INSTALLATION_DIR,$TARGET_HOME,n-o-d}

export PROOT_TMP_DIR=.fakedroid/env/$INSTALLATION_DIR/proot/tmp
export PROOT_L2S_DIR=.fakedroid/env/$INSTALLATION_DIR/proot/l2s
mkdir -p $PROOT_TMP_DIR
mkdir -p $PROOT_L2S_DIR

PASSTHROUGH_VARS=''
PASSTHROUGH_VARS+=" PROOT_TMP_DIR=$PROOT_TMP_DIR"
PASSTHROUGH_VARS+=" PROOT_L2S_DIR=$PROOT_L2S_DIR"
PASSTHROUGH_VARS+=" TERM=$TERM"
PASSTHROUGH_VARS+=" HOME=$TARGET_HOME"
PASSTHROUGH_VARS+=" USER=$USER"
set +u
[[ -n "$CACHIX_SIGNING_KEY" ]] && \
    PASSTHROUGH_VARS+=" CACHIX_SIGNING_KEY=$CACHIX_SIGNING_KEY"
set -u

PROOT_ARGS=''
PROOT_ARGS+=' -r .fakedroid/env'
PROOT_ARGS+=" -q $QEMU"
PROOT_ARGS+=" -w $TARGET_HOME"
PROOT_ARGS+=" -b .fakedroid/env/$INSTALLATION_DIR/nix:/nix"
PROOT_ARGS+=" -b .fakedroid/env/$INSTALLATION_DIR/bin:/bin"
PROOT_ARGS+=" -b .fakedroid/env/$INSTALLATION_DIR/etc:/etc"
PROOT_ARGS+=" -b .fakedroid/env/$INSTALLATION_DIR/tmp:/tmp"
PROOT_ARGS+=" -b .fakedroid/env/$INSTALLATION_DIR/usr:/usr"
PROOT_ARGS+=' -b /dev'
PROOT_ARGS+=' -b /proc'
PROOT_ARGS+=' -b /sys'
PROOT_ARGS+=' --link2symlink'


# Procure a static QEMU for user emulation and a proot with our patches:

[[ -e .fakedroid/inj/qemu-aarch64 ]] || wget $QEMU_URL -O $QEMU
chmod +x $QEMU

PROOT=$(nix-build --no-out-link tests/proot-test.nix)/bin/proot


# Do the first install if not installed yet:

if [[ ! -e .fakedroid/env/$INSTALLATION_DIR/etc ||
        -e .fakedroid/env/$INSTALLATION_DIR/etc/UNINITIALIZED ]]; then
    # Build a zipball:
    nix build --show-trace -f pkgs \
        --argstr arch aarch64 \
        --argstr nixOnDroidChannelURL file:///n-o-d/archive.tar.gz \
        bootstrapZip -o .fakedroid/inj/nix-on-droid-aarch64
    ZIPBALL=$(realpath .fakedroid/inj/nix-on-droid-aarch64/bootstrap-aarch64.zip)
    # Unpack the zipball the way the Android app does it:
    pushd .fakedroid/env/$INSTALLATION_DIR
        unzip "$ZIPBALL"
        chmod -R u+rw .  # unzip results in -r-xr-xr-x files and directories
        while read e; do
            SYM_TGT=${e%%←*}
            SYM_SRC=${e##*←}
            ln -sf "$SYM_TGT" "$SYM_SRC"
        done < SYMLINKS.txt
        while read e; do
            chmod +x "$e"
        done < EXECUTABLES.txt
        rm SYMLINKS.txt EXECUTABLES.txt
    popd
fi


# Inject nix-on-droid version under test into the environment.
# Uncommitted chages won't be picked up, just HEAD.
# /n-o-d/archive.tar.gz is used as a channel, /n-o-d/unpacked --- as a flake.

rm -rf .fakedroid/env/n-o-d; mkdir -p .fakedroid/env/n-o-d/unpacked
git archive --format=tar --prefix n-o-d/ HEAD \
    > .fakedroid/env/n-o-d/archive.tar
tar --strip-components=1 -xf \
    .fakedroid/env/n-o-d/archive.tar -C .fakedroid/env/n-o-d/unpacked
gzip .fakedroid/env/n-o-d/archive.tar


# The 'first boot' proot invocation:

SH=$(readlink .fakedroid/env/$INSTALLATION_DIR/bin/sh)

# 'first boot' execs interactive bash unconditionally;
# makes sense on device, requires us to work around it here though
env -i $PASSTHROUGH_VARS $PROOT $PROOT_ARGS \
    $INSTALLATION_DIR/$SH ${INSTALLATION_DIR}/usr/lib/login-inner <<<'echo OK'

# this is usually done by login on 'first reboot'
[[ -e .fakedroid/env/${INSTALLATION_DIR}/usr/lib/.login-inner.new ]] &&
    mv .fakedroid/env/${INSTALLATION_DIR}/usr/lib/.login-inner.new \
        .fakedroid/env/${INSTALLATION_DIR}/usr/lib/login-inner


# Actually execute something inside that fakedroid environment:

exec env -i $PASSTHROUGH_VARS $PROOT $PROOT_ARGS \
    $INSTALLATION_DIR/$SH ${INSTALLATION_DIR}/usr/lib/login-inner "$@"
