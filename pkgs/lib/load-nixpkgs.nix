# Copyright (c) 2019-2021, see AUTHORS. Licensed under MIT License, see LICENSE.

let
  defaultNixpkgsArgs = {
    config = { };
    overlays = [ ];
  };

  # head of nixos-21.11 as of 2021-12-01
  # note: when updating nixpkgs, update store paths of proot-termux in modules/environment/login/default.nix
  pinnedPkgsSrc = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/a640d8394f34714578f3e6335fc767d0755d78f9.tar.gz";
    sha256 = "1dyyzgcmlhpsdb4ngiy8m0x10qmh0r56ky75r8ppvvh730m3lhfj";
  };
in

args: import pinnedPkgsSrc (args // defaultNixpkgsArgs)
