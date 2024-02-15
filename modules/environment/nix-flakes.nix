# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

# Based on
# https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/config/nix-flakes.nix
# (Copyright (c) 2003-2022 Eelco Dolstra and the Nixpkgs/NixOS contributors,
# licensed under MIT License as well)

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.nix;
in

{
  ###### interface

  options = {
    nix = {
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
        description = "A system-wide flake registry.";
      };
    };
  };


  ###### implementation

  config = {
    environment.etc = {
      "nix/registry.json".text = builtins.toJSON {
        version = 2;
        flakes = mapAttrsToList (_n: v: { inherit (v) from to exact; }) cfg.registry;
      };
    };
  };

}
