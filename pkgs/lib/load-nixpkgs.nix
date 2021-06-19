# Copyright (c) 2019-2021, see AUTHORS. Licensed under MIT License, see LICENSE.

let
  defaultNixpkgsArgs = {
    config = { };
    overlays = [ ];
  };

  # head of nixos-21.05 as of 2021-06-24
  # note: when updating nixpkgs, update store paths of proot-termux in modules/environment/login/default.nix
  pinnedPkgsSrc = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/0b8b127125e5271f5c8636680b6fe274844aaa9d.tar.gz";
    sha256 = "1rjb1q28ivaf20aqj3v60kzjyi5lqb3krag0k8wwjqch45ik2f86";
  };
in

args: import pinnedPkgsSrc (args // defaultNixpkgsArgs)
