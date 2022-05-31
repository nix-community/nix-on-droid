# Copyright (c) 2019-2021, see AUTHORS. Licensed under MIT License, see LICENSE.

let
  defaultNixpkgsArgs = {
    config = { };
    overlays = [ ];
  };

  # head of nixos-22.05 as of 2022-05-31
  # note: when updating nixpkgs, update store paths of proot-termux in modules/environment/login/default.nix
  pinnedPkgsSrc = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/a634c8f6c1fbf9b9730e01764999666f3436f10a.tar.gz";
    sha256 = "1d40v43x972li5fg7jadxkj341li41mf2cl6vv7xi6j80rkq45q4";
  };
in

args: import pinnedPkgsSrc (args // defaultNixpkgsArgs)
