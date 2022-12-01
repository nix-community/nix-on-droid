# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

{ super }:

let
  # head of nixos-22.11 as of 2022-12-01
  pinnedPkgsSrc = super.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "596a8e828c5dfa504f91918d0fa4152db3ab5502";
    sha256 = "sha256-YnhZGHgb4C3Q7DSGisO/stc50jFb9F/MzHeKS4giotg=";
  };
in

import pinnedPkgsSrc {
  inherit (super) config system;
  overlays = [ ];
}
