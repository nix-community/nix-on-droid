# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

{ super }:

let
  pinnedPkgsSrc = super.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "7e8454fb856573967a70f61116e15f879f2e3f6a";
    sha256 = "0lnbjjvj0ivpi9pxar0fyk8ggybxv70c5s0hpsqf5d71lzdpxpj8";
  };
in

import pinnedPkgsSrc {
  inherit (super) config;
  overlays = [ ];
}
