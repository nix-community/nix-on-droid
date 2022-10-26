# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

# Inspired by
# https://github.com/rycee/home-manager/blob/master/modules/misc/nixpkgs.nix
# (Copyright (c) 2017-2019 Robert Helgesson and Home Manager contributors,
#  licensed under MIT License as well)

{ config, lib, pkgs, isFlake, ... }:

with lib;

let

  isConfig = x:
    builtins.isAttrs x || builtins.isFunction x;

  optCall = f: x:
    if builtins.isFunction f
    then f x
    else f;

  mergeConfig = lhs_: rhs_:
    let
      lhs = optCall lhs_ { inherit pkgs; };
      rhs = optCall rhs_ { inherit pkgs; };
    in
    lhs // rhs //
    optionalAttrs (lhs ? packageOverrides) {
      packageOverrides = pkgs:
        optCall lhs.packageOverrides pkgs //
        optCall (attrByPath [ "packageOverrides" ] { } rhs) pkgs;
    } //
    optionalAttrs (lhs ? perlPackageOverrides) {
      perlPackageOverrides = pkgs:
        optCall lhs.perlPackageOverrides pkgs //
        optCall (attrByPath [ "perlPackageOverrides" ] { } rhs) pkgs;
    };

  configType = mkOptionType {
    name = "nixpkgs-config";
    description = "nixpkgs config";
    check = x:
      let
        traceXIfNot = c:
          if c x then true
          else lib.traceSeqN 1 x false;
      in
      traceXIfNot isConfig;
    merge = _args: fold (def: mergeConfig def.value) { };
  };

  overlayType = mkOptionType {
    name = "nixpkgs-overlay";
    description = "nixpkgs overlay";
    check = builtins.isFunction;
    merge = lib.mergeOneOption;
  };
in

{

  ###### interface

  options = {

    nixpkgs = {
      config = mkOption {
        default = null;
        example = { allowBroken = true; };
        type = types.nullOr configType;
        description = ''
          The configuration of the Nix Packages collection. (For
          details, see the Nixpkgs documentation.) It allows you to set
          package configuration options.

          </para><para>

          If <literal>null</literal>, then configuration is taken from
          the fallback location, for example,
          <filename>~/.config/nixpkgs/config.nix</filename>.

          </para><para>

          Note, this option will not apply outside your Nix-on-Droid
          configuration like when installing manually through
          <command>nix-env</command> or in your Home Manager config.

          </para><para>

          If you want to apply it both inside Home Manager and outside
          you need to include something like

          <programlisting language="nix">
          { pkgs, config, ...}:

          {
            # for Nix-on-Droid
            nixpkgs.config = import ./nixpkgs-config.nix;

            # for Home Manager
            home-manager.config.nixpkgs.config = import ./nixpkgs-config.nix;
            # -or-
            home-manager.config =
              { pkgs, ... }:
              {
                # for Home Manager
                nixpkgs.config = import ./nixpkgs-config.nix;
                # for commands like nix-env
                xdg.configFile."nixpkgs/config.nix".source = ./nixpkgs-config.nix;
              };
          }
          </programlisting>

          in your Nix-on-Droid configuration.
        '';
      };

      overlays = mkOption {
        default = null;
        example = literalExpression ''
          [ (self: super: {
              openssh = super.openssh.override {
                hpnSupport = true;
                withKerberos = true;
                kerberos = self.libkrb5;
              };
            };
          ) ]
        '';
        type = types.nullOr (types.listOf overlayType);
        description = ''
          List of overlays to use with the Nix Packages collection. (For
          details, see the Nixpkgs documentation.) It allows you to
          override packages globally. This is a function that takes as
          an argument the <emphasis>original</emphasis> Nixpkgs. The
          first argument should be used for finding dependencies, and
          the second should be used for overriding recipes.

          </para><para>

          If <literal>null</literal>, then the overlays are taken from
          the fallback location, for example,
          <filename>~/.config/nixpkgs/overlays</filename>.

          </para><para>

          Like <varname>nixpkgs.config</varname> this option only
          applies within the Nix-on-Droid configuration. See
          <varname>nixpkgs.config</varname> for a suggested setup that
          works both internally for Nix-on-Droid or Home Manager and
          externally.
        '';
      };
    };

  };


  ###### implementation

  config = {

    assertions = [
      {
        assertion = isFlake -> config.nixpkgs.config == null && (config.nixpkgs.overlays == null || config.nixpkgs.overlays == [ ]);
        message = "In a flake setup, the options nixpkgs.* should not be used. Instead, rely on the provided flake "
          + "outputs and pass in the necessary nixpkgs object.";
      }
    ];

  };
}
