# Copyright (c) 2019-2023, see AUTHORS. Licensed under MIT License, see LICENSE.

{ super }:

let
  # head of nixos-23.11 as of 2024-02-17
  pinnedPkgsSrc = super.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "1d1817869c47682a6bee85b5b0a6537b6c0fba26";
    sha256 = "sha256-sS4AItZeUnAei6v8FqxNlm+/27MPlfoGym/TZP0rmH0=";
  };
in

import pinnedPkgsSrc {
  inherit (super) config system;
  overlays = [ ];
}
