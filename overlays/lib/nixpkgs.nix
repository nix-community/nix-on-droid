# Copyright (c) 2019-2021, see AUTHORS. Licensed under MIT License, see LICENSE.

{ super }:

let
  # head of nixos-22.05 as of 2022-05-31
  pinnedPkgsSrc = super.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "a634c8f6c1fbf9b9730e01764999666f3436f10a";
    sha256 = "1d40v43x972li5fg7jadxkj341li41mf2cl6vv7xi6j80rkq45q4";
  };
in

import pinnedPkgsSrc {
  inherit (super) config system;
  overlays = [ ];
}
