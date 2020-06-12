# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

{ super }:

let
  # head of nixos-20.03 as of 2020-06-11
  pinnedPkgsSrc = super.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "8b071be7512bd2cd0ff5c3bdf60f01ab4eb94abd";
    sha256 = "079rzd17y2pk48kh70pbp4a7mh56vi2b49lzd365ckh38gdv702z";
  };
in

import pinnedPkgsSrc {
  inherit (super) config;
  overlays = [ ];
}
