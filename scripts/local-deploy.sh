#!/usr/bin/env bash
set -xevo pipefail
tmp=`mktemp -d`/n-o-d
mkdir $tmp
cd "$(dirname "$0")"/..
git -C . archive --format=tar.gz --prefix n-o-d/ HEAD > $tmp/archive.tar.gz
ARCHES=x86_64 nix run .#deploy -- file:///data/local/tmp/n-o-d/archive.tar.gz --rsync-target $tmp/
adb shell 'rm -rf /data/local/tmp/n-o-d'
adb push $tmp /data/local/tmp/
adb shell 'cd /data/local/tmp/n-o-d && tar xzof archive.tar.gz && mv n-o-d unpacked'
