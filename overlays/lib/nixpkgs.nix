# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ super }:

let
  # head of nixos-24.05 as of 2024-07-06
  pinnedPkgsSrc = super.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "49ee0e94463abada1de470c9c07bfc12b36dcf40";
    sha256 = "sha256-WrDV0FPMVd2Sq9hkR5LNHudS3OSMmUrs90JUTN+MXpA=";
  };
in

import pinnedPkgsSrc {
  inherit (super) config system;
  overlays = [ ];
}
