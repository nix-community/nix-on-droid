# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

with import <nixpkgs> { };

let
  src = import ./src;
in

lib.genAttrs
  [ "aarch64" "i686" ]
  (arch: (src { inherit arch; }) // { recurseForDerivations = true; })
