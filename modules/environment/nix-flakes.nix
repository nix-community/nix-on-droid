# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

# Based on
# https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/config/nix-flakes.nix
# (Copyright (c) 2003-2022 Eelco Dolstra and the Nixpkgs/NixOS contributors,
# licensed under MIT License as well)

{ config, lib, pkgs, nixpkgs, ... }:

with lib;

let
  cfg = config.nix;
in

{
  imports = [
    # Use options and config from upstream nix-flakes.nix
    "${nixpkgs}/nixos/modules/config/nix-flakes.nix"
  ];
}
