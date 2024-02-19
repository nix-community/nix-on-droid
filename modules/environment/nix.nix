# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

# Based on
# https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/system/nix-daemon.nix
# and
# https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/config/nix.nix
# (Copyright (c) 2003-2022 Eelco Dolstra and the Nixpkgs/NixOS contributors,
# licensed under MIT License as well)

{ config, lib, pkgs, nixpkgs, ... }:

with lib;

let
  cfg = config.nix;
  renameNixOpt = old: new:
    mkRenamedOptionModuleWith {
      sinceRelease = 2205;
      from = [ "nix" old ];
      to = [ "nix" "settings" new ];
    };
in

{
  imports = [
    # Use options and config from upstream nix.nix
    "${nixpkgs}/nixos/modules/config/nix.nix"
    # Backward-compatibility with pre-`settings` options.
    (renameNixOpt "substituters" "substituters")
    (renameNixOpt "trustedPublicKeys" "trusted-public-keys")
  ];

  ###### interface

  options = {

    nix = {

      ## From nix-daemon.nix

      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to enable Nix.
          Disabling Nix is not supported in NixOnDroid. This option is here to
          make it compatible to the upstream NixOS modules.
        '';
      };

      package = mkOption {
        type = types.package;
        default = pkgs.nix;
        defaultText = literalExpression "pkgs.nix";
        description = ''
          This option specifies the Nix package instance to use throughout the system.
        '';
      };

    };

  };


  ###### implementation

  config = {
    nix = {
      enable = true;
      settings.substituters = [
        "https://cache.nixos.org"
        "https://nix-on-droid.cachix.org"
      ];
      settings.trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-on-droid.cachix.org-1:56snoMJTXmDRC1Ei24CmKoUqvHJ9XCp+nidK7qkMQrU="
      ];
    };
  };

}
