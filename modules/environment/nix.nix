# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

# Based on
# https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/misc/nix-daemon.nix
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
    (renameNixOpt "extraConfig" "extraOptions")
  ];

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

      nixPath = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          The default Nix expression search path, used by the Nix
          evaluator to look up paths enclosed in angle brackets
          (e.g. <literal>&lt;nixpkgs&gt;</literal>).
        '';
      };

      registry = mkOption {
        type = types.attrsOf (types.submodule (
          let
            referenceAttrs = with types; attrsOf (oneOf [
              str
              int
              bool
              package
            ]);
          in
          { config, name, ... }:
          {
            options = {
              from = mkOption {
                type = referenceAttrs;
                example = { type = "indirect"; id = "nixpkgs"; };
                description = "The flake reference to be rewritten.";
              };
              to = mkOption {
                type = referenceAttrs;
                example = { type = "github"; owner = "my-org"; repo = "my-nixpkgs"; };
                description = "The flake reference <option>from</option> is rewritten to.";
              };
              flake = mkOption {
                type = types.nullOr types.attrs;
                default = null;
                example = literalExpression "nixpkgs";
                description = ''
                  The flake input <option>from</option> is rewritten to.
                '';
              };
              exact = mkOption {
                type = types.bool;
                default = true;
                description = ''
                  Whether the <option>from</option> reference needs to match exactly. If set,
                  a <option>from</option> reference like <literal>nixpkgs</literal> does not
                  match with a reference like <literal>nixpkgs/nixos-20.03</literal>.
                '';
              };
            };
            config = {
              from = mkDefault { type = "indirect"; id = name; };
              to = mkIf (config.flake != null) (mkDefault
                {
                  type = "path";
                  path = config.flake.outPath;
                } // filterAttrs
                (n: _: n == "lastModified" || n == "rev" || n == "revCount" || n == "narHash")
                config.flake);
            };
          }
        ));
        default = { };
        description = ''
          A system-wide flake registry.
        '';
      };

      substituters = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          A list of URLs of substituters.  The official NixOS and nix-on-droid
          substituters are added by default.
        '';
      };

      trustedPublicKeys = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          A list of public keys.  When paths are copied from another Nix store (such as a
          binary cache), they must be signed with one of these keys.  The official NixOS
          and nix-on-droid public keys are added by default.
        '';
      };

      extraOptions = mkOption {
        type = types.lines;
        default = "";
        description = "Extra config to be appended to /etc/nix/nix.conf.";
      };
    };

  };


  ###### implementation

  config = mkMerge [
    {
      environment.etc = {
        "nix/nix.conf".text = ''
          sandbox = false
          substituters = ${concatStringsSep " " cfg.substituters}
          trusted-public-keys = ${concatStringsSep " " cfg.trustedPublicKeys}
          ${cfg.extraOptions}
        '';

        "nix/registry.json".text = builtins.toJSON {
          version = 2;
          flakes = mapAttrsToList (_n: v: { inherit (v) from to exact; }) cfg.registry;
        };
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
    }

    (mkIf (cfg.nixPath != [ ]) {
      environment.sessionVariables.NIX_PATH = concatStringsSep ":" cfg.nixPath;
    })
  ];

}
