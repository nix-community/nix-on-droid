# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

let
  defaultNixpkgsArgs = {
    config = { };
    overlays = [ ];
  };

  # head of nixos-19.09 as of 2019-10-14
  # note: when updating nixpkgs, update store paths of proot-termux in modules/environment/login/default.nix
  pinnedPkgsSrc = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/45a25ff41a2309099ff2e70b2f37debd5e567618.tar.gz";
    sha256 = "0w37p98i47d7snhckz8a3a60v0f05b5047vsm4rczink9mk9x7r3";
  };
in

args: import pinnedPkgsSrc (args // defaultNixpkgsArgs)
