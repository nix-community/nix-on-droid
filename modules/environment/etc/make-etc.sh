# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

# inspired by https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/etc/make-etc.sh

source $stdenv/setup

mkdir -p $out

set -f
sources_=($sources)
targets_=($targets)
set +f

for ((i = 0; i < ${#targets_[@]}; i++)); do
    source="${sources_[$i]}"
    target="${targets_[$i]}"

    if [[ "$source" =~ '*' ]]; then

        # If the source name contains '*', perform globbing.
        mkdir -p $out/etc/$target
        for fn in $source; do
            ln -s "$fn" $out/etc/$target/
        done

    else

        mkdir -p $out/etc/$(dirname $target)
        if ! [ -e $out/etc/$target ]; then
            ln -s $source $out/etc/$target
        else
            echo "duplicate entry $target -> $source"
            if test "$(readlink $out/etc/$target)" != "$source"; then
                echo "mismatched duplicate entry $(readlink $out/etc/$target) <-> $source"
                exit 1
            fi
        fi

    fi
done
