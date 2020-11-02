# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

{ super }:

let
  # head of nixos-20.09 as of 2020-11-07
  pinnedPkgsSrc = super.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "d105075a1fd870b1d1617a6008cb38b443e65433";
    sha256 = "1jcs44wn0s6mlf2jps25bvcai1rij9b2dil6zcj8zqwf2i8xmqjh";
  };
in

import pinnedPkgsSrc {
  inherit (super) config;
  overlays = [ ];
}
