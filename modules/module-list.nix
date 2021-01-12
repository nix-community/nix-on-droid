# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

{ pkgs }:

[
  ./build/activation.nix
  ./build/config.nix
  ./environment/etc
  ./environment/files.nix
  ./environment/links.nix
  ./environment/login
  ./environment/path.nix
  ./environment/session-init.nix
  ./home-manager.nix
  ./nixpkgs.nix
  ./time.nix
  ./user.nix
  ./version.nix
  ./workaround-make.nix
  (pkgs.path + "/nixos/modules/misc/assertions.nix")
]
