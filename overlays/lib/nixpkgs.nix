# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

{ super }:

let
  # head of nixos-22.11 as of 2023-01-05
  pinnedPkgsSrc = super.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "37d8b66e6acc039dd5d5504aa1fdf0f2847444c5";
    sha256 = "sha256-/DoGlsSyAwi0E4wRMjRnNve6yo4x5JlBeyGQRvSrSjs=";
  };
in

import pinnedPkgsSrc {
  inherit (super) config system;
  overlays = [ ];
}
