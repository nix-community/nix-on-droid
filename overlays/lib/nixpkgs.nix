# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ super }:

let
  # head of nixos-24.05 as of 2024-06-05
  pinnedPkgsSrc = super.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "b3b2b28c1daa04fe2ae47c21bb76fd226eac4ca1";
    sha256 = "";
  };
in

import pinnedPkgsSrc {
  inherit (super) config system;
  overlays = [ ];
}
