# Copyright (c) 2019-2023, see AUTHORS. Licensed under MIT License, see LICENSE.

{ super }:

let
  # head of nixos-23.05 as of 2023-06-18
  pinnedPkgsSrc = super.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "c7ff1b9b95620ce8728c0d7bd501c458e6da9e04";
    sha256 = "sha256-J1bX9plPCFhTSh6E3TWn9XSxggBh/zDD4xigyaIQBy8=";
  };
in

import pinnedPkgsSrc {
  inherit (super) config system;
  overlays = [ ];
}
