# Copyright (c) 2019-2021, see AUTHORS. Licensed under MIT License, see LICENSE.

{ super }:

let
  # head of nixos-21.05 as of 2021-06-24
  pinnedPkgsSrc = super.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "0b8b127125e5271f5c8636680b6fe274844aaa9d";
    sha256 = "1rjb1q28ivaf20aqj3v60kzjyi5lqb3krag0k8wwjqch45ik2f86";
  };
in

import pinnedPkgsSrc {
  inherit (super) config system;
  overlays = [ ];
}
