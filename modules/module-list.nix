# Copyright (c) 2019-2021, see AUTHORS. Licensed under MIT License, see LICENSE.

{ pkgs, isFlake }:

[
  ./build/activation.nix
  ./build/config.nix
  ./environment/ca.nix
  ./environment/etc
  ./environment/links.nix
  ./environment/login
  ./environment/networking.nix
  ./environment/nix.nix
  ./environment/path.nix
  ./environment/session-init.nix
  ./environment/shell.nix
  ./home-manager.nix
  ./nixpkgs/options.nix
  ./supervisord.nix
  ./terminal.nix
  ./time.nix
  ./upgrade.nix
  ./user.nix
  ./version.nix
  (pkgs.path + "/nixos/modules/misc/assertions.nix")
] ++ pkgs.lib.optionals (!isFlake) [ ./nixpkgs/config.nix ]
