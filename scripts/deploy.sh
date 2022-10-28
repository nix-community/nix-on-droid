#!@bash@/bin/bash
set -euo pipefail

PATH=@path@

if [[ $# -ne 2 ]]; then
    cat >&2 <<EOF

USAGE: nix run .#deploy -- <public_url> <rsync_target>

Builds bootstrap zip ball and source code tar ball (for usage as a channel or
flake) and uploads it to the directory specified in <rsync_target>. The
contents of this directory should be reachable by the android device with
<public_url>.

Example:
$ nix run .#deploy -- 'https://example.com/bootstrap' 'user@host:/path/to/bootstrap'

EOF
    exit 1
fi

PUBLIC_URL="$1"
RSYNC_TARGET="$2"

# this allows to run this script from every place in this git repo
REPO_DIR="$(git rev-parse --show-toplevel)"

cd "$REPO_DIR"

SOURCE_FILE="source.tar.gz"

function log() {
    echo "> $*"
}


log "building proot..."
PROOT="$(nix build --no-link --print-out-paths ".#prootTermux")"


PROOT_HASH_FILE="modules/environment/login/default.nix"
log "patching proot path in $PROOT_HASH_FILE..."
grep "prootStatic = \"/nix/store/" "$PROOT_HASH_FILE"
sed -i "s|prootStatic = \"/nix/store/.*\";|prootStatic = \"$PROOT\";|" "$PROOT_HASH_FILE"
grep "prootStatic = \"/nix/store/" "$PROOT_HASH_FILE"


log "building bootstrapZip..."
export NIX_ON_DROID_CHANNEL_URL="$PUBLIC_URL/$SOURCE_FILE"
export NIX_ON_DROID_FLAKE_URL="$PUBLIC_URL/$SOURCE_FILE"
BOOTSTRAP_ZIP="$(nix build --no-link --print-out-paths --impure ".#bootstrapZip")"


log "creating tar ball of current HEAD..."
git archive --prefix nix-on-droid/ --output "$SOURCE_FILE" HEAD


log "uploading artifacts..."
rsync --progress \
    "$SOURCE_FILE" \
    "$BOOTSTRAP_ZIP/bootstrap-aarch64.zip" \
    "$RSYNC_TARGET"
