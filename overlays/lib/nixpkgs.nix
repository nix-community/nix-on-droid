# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

{ super }:

let
  # head of nixos-22.05 as of 2022-06-27
  pinnedPkgsSrc = super.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "cd90e773eae83ba7733d2377b6cdf84d45558780";
    sha256 = "1b2wn1ncx9x4651vfcgyqrm93pd7ghnrgqjbkf6ckkpidah69m03";
  };
in

import pinnedPkgsSrc {
  inherit (super) config system;
  overlays = [ ];
}
