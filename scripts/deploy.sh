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

Examples:
$ nix run .#deploy -- 'https://example.com/bootstrap/source.tar.gz' 'user@host:/path/to/bootstrap'
$ nix run .#deploy -- 'github:USER/nix-on-droid/BRANCH' 'user@host:/path/to/bootstrap'

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


if [[ "$PUBLIC_URL" =~ ^github:(.*)/(.*)/(.*) ]]; then
    export NIX_ON_DROID_CHANNEL_URL="https://github.com/${BASH_REMATCH[1]}/${BASH_REMATCH[2]}/archive/${BASH_REMATCH[3]}.tar.gz"
else
    [[ "$PUBLIC_URL" =~ ^https?:// ]] || \
    [[ "$PUBLIC_URL" =~ ^file:/// ]] || \
        { echo "unsupported url $PUBLIC_URL" >&2; exit 1; }
    export NIX_ON_DROID_CHANNEL_URL="$PUBLIC_URL"
fi
# special case for local / CI testing
if [[ "$PUBLIC_URL" =~ ^file:///(.*)/archive.tar.gz ]]; then
    export NIX_ON_DROID_FLAKE_URL="/${BASH_REMATCH[1]}/unpacked"
else
    export NIX_ON_DROID_FLAKE_URL="$PUBLIC_URL"
fi
log "NIX_ON_DROID_CHANNEL_URL=$NIX_ON_DROID_CHANNEL_URL"
log "NIX_ON_DROID_FLAKE_URL=$NIX_ON_DROID_FLAKE_URL"


log "building proot..."
PROOT="$(nix build --no-link --print-out-paths ".#prootTermux")"


PROOT_HASH_FILE="modules/environment/login/default.nix"
log "patching proot path in $PROOT_HASH_FILE..."
grep "prootStatic = \"/nix/store/" "$PROOT_HASH_FILE"
sed -i "s|prootStatic = \"/nix/store/.*\";|prootStatic = \"$PROOT\";|" "$PROOT_HASH_FILE"
grep "prootStatic = \"/nix/store/" "$PROOT_HASH_FILE"


log "building bootstrapZip..."
BOOTSTRAP_ZIP="$(nix build --no-link --print-out-paths --impure ".#bootstrapZip")"


log "creating tar ball of current HEAD..."
git archive --prefix nix-on-droid/ --output "$SOURCE_FILE" HEAD


log "uploading artifacts..."
rsync --progress \
    "$SOURCE_FILE" \
    "$BOOTSTRAP_ZIP/bootstrap-aarch64.zip" \
    "$RSYNC_TARGET"
