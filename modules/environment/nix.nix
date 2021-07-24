# Copyright (c) 2019-2021, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.nix;
in

{

  ###### interface

  options = {

    nix = {
      package = mkOption {
        type = types.package;
        default = pkgs.nix;
        defaultText = "pkgs.nix";
        description = ''
          This option specifies the Nix package instance to use throughout the system.
        '';
      };

      substituters = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          A list of URLs of substituters.  The official NixOS and nix-on-droid
          substituters are added by default.
        '';
      };

      trustedPublicKeys = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          A list of public keys.  When paths are copied from another Nix store (such as a
          binary cache), they must be signed with one of these keys.  The official NixOS
          and nix-on-droid public keys are added by default.
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Extra config to be appended to /etc/nix/nix.conf.";
      };
    };

  };


  ###### implementation

  config = {

    environment.etc = {
      "nix/nix.conf".text = ''
        sandbox = false
        substituters = ${concatStringsSep " " cfg.substituters}
        trusted-public-keys = ${concatStringsSep " " cfg.trustedPublicKeys}
        ${cfg.extraConfig}
      '';
    };

    nix = {
      substituters = [
        "https://cache.nixos.org"
        "https://nix-on-droid.cachix.org"
      ];
      trustedPublicKeys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-on-droid.cachix.org-1:56snoMJTXmDRC1Ei24CmKoUqvHJ9XCp+nidK7qkMQrU="
      ];
    };

  };

}
