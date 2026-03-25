#!/usr/bin/env bash
# Serve the bootstrap zip files on the local network for joNix app installation.
# Usage: ./scripts/serve-bootstrap.sh [port]
#
# The app on the phone should be pointed at http://<your-lan-ip>:<port>
# Default port: 8462

set -euo pipefail

PORT="${1:-8462}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Build bootstrap zips if not already built
AARCH64_ZIP=""
X86_64_ZIP=""

for result in "$REPO_DIR"/result*; do
    if [ -f "$result/bootstrap-aarch64.zip" ]; then
        AARCH64_ZIP="$result/bootstrap-aarch64.zip"
    fi
    if [ -f "$result/bootstrap-x86_64.zip" ]; then
        X86_64_ZIP="$result/bootstrap-x86_64.zip"
    fi
done

if [ -z "$AARCH64_ZIP" ] || [ -z "$X86_64_ZIP" ]; then
    echo "Bootstrap zips not found in result symlinks. Building..."
    echo "Building aarch64..."
    nix build "$REPO_DIR#bootstrapZip-aarch64" --impure -o "$REPO_DIR/result-aarch64"
    AARCH64_ZIP="$REPO_DIR/result-aarch64/bootstrap-aarch64.zip"

    echo "Building x86_64..."
    nix build "$REPO_DIR#bootstrapZip-x86_64" --impure -o "$REPO_DIR/result-x86_64"
    X86_64_ZIP="$REPO_DIR/result-x86_64/bootstrap-x86_64.zip"
fi

# Create a temporary directory with symlinks for serving
SERVE_DIR=$(mktemp -d)
trap 'rm -rf "$SERVE_DIR"' EXIT

ln -sf "$AARCH64_ZIP" "$SERVE_DIR/bootstrap-aarch64.zip"
ln -sf "$X86_64_ZIP" "$SERVE_DIR/bootstrap-x86_64.zip"

echo "============================================"
echo "  joNix Bootstrap Server"
echo "============================================"
echo ""
echo "  Serving on: http://0.0.0.0:${PORT}"
echo ""
echo "  Files:"
echo "    bootstrap-aarch64.zip -> $AARCH64_ZIP"
echo "    bootstrap-x86_64.zip -> $X86_64_ZIP"
echo ""
LAN_IP=$(ip -4 addr show scope global | grep -oP '(?<=inet\s)\d+\.\d+\.\d+\.\d+' | head -1)
echo "  In the joNix app, enter this URL:"
echo "    http://${LAN_IP}:${PORT}"
echo ""
echo "  Press Ctrl+C to stop."
echo "============================================"

cd "$SERVE_DIR"
exec nix-shell -p python3 --run "python3 -m http.server $PORT --bind 0.0.0.0"
