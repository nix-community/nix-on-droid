# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ arch, initialBuild ? true }:

assert builtins.elem arch [ "aarch64" "i686" ];

let
  pkgs = import <nixpkgs> { };

  pkgsList = import ./pkgs-list.nix {
    inherit arch;
    inherit (pkgs) fetchFromGitHub;
  };
in

import ./pkgs {
  inherit arch initialBuild;
  inherit (pkgsList) pinnedPkgs crossPkgs crossStaticPkgs;
  buildPkgs = if initialBuild then pkgsList.pinnedPkgs else pkgs;
}
