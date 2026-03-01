# Copyright (c) 2019-2026, see AUTHORS. Licensed under MIT License, see LICENSE.

{ super }:

let
  # head of nixos-25.11 as of 2026-03-01
  pinnedPkgsSrc = super.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "1267bb4920d0fc06ea916734c11b0bf004bbe17e";
    sha256 = "";
  };
in

import pinnedPkgsSrc {
  inherit (super) config system;
  overlays = [ ];
}
