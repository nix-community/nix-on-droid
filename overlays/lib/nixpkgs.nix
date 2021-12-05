# Copyright (c) 2019-2021, see AUTHORS. Licensed under MIT License, see LICENSE.

{ super }:

let
  # head of nixos-21.11 as of 2021-12-01
  pinnedPkgsSrc = super.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "a640d8394f34714578f3e6335fc767d0755d78f9";
    sha256 = "1dyyzgcmlhpsdb4ngiy8m0x10qmh0r56ky75r8ppvvh730m3lhfj";
  };
in

import pinnedPkgsSrc {
  inherit (super) config system;
  overlays = [ ];
}
