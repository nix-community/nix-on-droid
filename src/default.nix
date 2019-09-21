# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ arch }:

assert builtins.elem arch [ "aarch64" "i686" ];

let
  nixpkgs = import <nixpkgs> { };

  pinnedPkgs = import ./pinned-pkgs.nix {
    inherit arch;
    inherit (nixpkgs) fetchFromGitHub;
  };
in

import ./pkgs {
  inherit arch;
  inherit (pinnedPkgs) buildPkgs crossPkgs crossStaticPkgs;
}
