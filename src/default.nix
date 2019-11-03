# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ arch
, initialBuild ? true
, nixOnDroidChannelURL ? "https://github.com/t184256/nix-on-droid-bootstrap/archive/master.tar.gz"
, nixpkgsChannelURL ? "https://nixos.org/channels/nixos-19.09"
}:

assert builtins.elem arch [ "aarch64" "i686" ];

let
  currentNixpkgs = import <nixpkgs> { };
  currentNixpkgsLib = currentNixpkgs.callPackage ./lib { };

  pinnedNixpkgs = currentNixpkgsLib.loadNixpkgs { };
  pinnedNixpkgsLib = pinnedNixpkgs.callPackage ./lib { };

  # use pinned nixpkgs only for initial build
  nixpkgs = if initialBuild then pinnedNixpkgs else currentNixpkgs;
  lib = if initialBuild then pinnedNixpkgsLib else currentNixpkgsLib;

  config = lib.buildConfig { inherit arch initialBuild nixOnDroidChannelURL nixpkgsChannelURL; };
in

import ./pkgs/top-level/all-packages.nix {
  inherit nixpkgs lib config;
}
