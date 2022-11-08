# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

{ pkgs, home-manager-path, isFlake }:

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
  ./terminal.nix
  ./time.nix
  ./upgrade.nix
  ./user.nix
  ./version.nix
  (pkgs.path + "/nixos/modules/misc/assertions.nix")

  {
    _file = ./module-list.nix;
    _module.args = {
      inherit home-manager-path isFlake;
      pkgs = pkgs.lib.mkDefault pkgs;
    };
  }
] ++ pkgs.lib.optionals (!isFlake) [ ./nixpkgs/config.nix ]
