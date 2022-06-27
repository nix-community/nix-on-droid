# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

let
  defaultNixpkgsArgs = {
    config = { };
    overlays = [ ];
  };

  # head of nixos-22.05 as of 2022-06-27
  # note: when updating nixpkgs, update store paths of proot-termux in modules/environment/login/default.nix
  pinnedPkgsSrc = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/cd90e773eae83ba7733d2377b6cdf84d45558780.tar.gz";
    sha256 = "1b2wn1ncx9x4651vfcgyqrm93pd7ghnrgqjbkf6ckkpidah69m03";
  };
in

args: import pinnedPkgsSrc (args // defaultNixpkgsArgs)
