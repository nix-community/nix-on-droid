# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

# Based on
# https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/system/nix-daemon.nix
# and
# https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/config/nix.nix
# (Copyright (c) 2003-2022 Eelco Dolstra and the Nixpkgs/NixOS contributors,
# licensed under MIT License as well)

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.nix;
  renameNixOpt = old: new:
    (mkRenamedOptionModule [ "nix" old ] [ "nix" new ]);
in

{
  # Backward-compatibility with the NixOS options.
  imports = [
    (renameNixOpt "binaryCaches" "substituters")
    (renameNixOpt "binaryCachePublicKeys" "trustedPublicKeys")
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

      ## From nix.nix

      substituters = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          A list of URLs of substituters.  The official NixOS and Nix-on-Droid
          substituters are added by default.
        '';
      };

      trustedPublicKeys = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          A list of public keys.  When paths are copied from another Nix store (such as a
          binary cache), they must be signed with one of these keys.  The official NixOS
          and Nix-on-Droid public keys are added by default.
        '';
      };

      extraOptions = mkOption {
        type = types.lines;
        default = "";
        description = "Extra config to be appended to <filename>/etc/nix/nix.conf</filename>.";
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
        ${cfg.extraOptions}
      '';
    };

    nix = {
      enable = true;
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
