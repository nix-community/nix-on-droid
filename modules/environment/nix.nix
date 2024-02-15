# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

# Based on
# https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/misc/nix-daemon.nix
# (Copyright (c) 2003-2023 Eelco Dolstra and the Nixpkgs/NixOS contributors)
# and
# https://github.com/nix-community/home-manager/blob/master/modules/misc/nix.nix
# (Copyright (c) 2017-2023 Home Manager contributors)
# both licensed under MIT License as well)

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.nix;

  renameNixOpt = old: new:
    (mkRenamedOptionModule [ "nix" old ] [ "nix" new ]);

  isNixAtLeast = versionAtLeast (getVersion cfg.package);

  nixConf =
    let

      mkValueString = v:
        if v == null then ""
        else if isInt v then toString v
        else if isBool v then boolToString v
        else if isFloat v then floatToString v
        else if isList v then toString v
        else if isDerivation v then toString v
        else if builtins.isPath v then toString v
        else if isString v then v
        else if strings.isConvertibleWithToString v then toString v
        else abort "The nix conf value: ${toPretty {} v} can not be encoded";

      mkKeyValue = k: v: "${escape [ "=" ] k} = ${mkValueString v}";

      mkKeyValuePairs = attrs: concatStringsSep "\n" (mapAttrsToList mkKeyValue attrs);

    in
    pkgs.writeTextFile {
      name = "nix.conf";
      text = ''
        # WARNING: this file is generated from the nix.* options in
        # your NixOS configuration, typically
        # /etc/nixos/configuration.nix.  Do not edit it!
        ${mkKeyValuePairs cfg.settings}
        ${cfg.extraOptions}
      '';
      checkPhase = lib.optionalString cfg.checkConfig (
        if pkgs.stdenv.hostPlatform != pkgs.stdenv.buildPlatform then ''
          echo "Ignoring validation for cross-compilation"
        ''
        else ''
          echo "Validating generated nix.conf"
          ln -s $out ./nix.conf
          set -e
          set +o pipefail
          NIX_CONF_DIR=$PWD \
            ${cfg.package}/bin/nix show-config ${optionalString (isNixAtLeast "2.3pre") "--no-net"} \
              ${optionalString (isNixAtLeast "2.4pre") "--option experimental-features nix-command"} \
            |& sed -e 's/^warning:/error:/' \
            | (! grep '${if cfg.checkAllErrors then "^error:" else "^error: unknown setting"}')
          set -o pipefail
        ''
      );
    };

  legacyConfMappings = {
    substituters = "substituters";
    trustedPublicKeys = "trusted-public-keys";
  };

  semanticConfType = with types;
    let
      confAtom = nullOr
        (oneOf [
          bool
          int
          float
          str
          path
          package
        ]) // {
        description = "Nix config atom (null, bool, int, float, str, path or package)";
      };
    in
    attrsOf (either confAtom (listOf confAtom));

in

{
  # Backward-compatibility with the NixOS options.
  imports = [
    (renameNixOpt "binaryCaches" "substituters")
    (renameNixOpt "binaryCachePublicKeys" "trustedPublicKeys")
    (renameNixOpt "extraConfig" "extraOptions")
  ] ++ mapAttrsToList (oldConf: newConf: mkRenamedOptionModule [ "nix" oldConf ] [ "nix" "settings" newConf ]) legacyConfMappings;

  ###### interface

  options = {

    nix = {
      package = mkOption {
        type = types.package;
        default = pkgs.nix;
        defaultText = literalExpression "pkgs.nix";
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
        description = "A system-wide flake registry.";
      };

      extraOptions = mkOption {
        type = types.lines;
        default = "";
        description = "Extra config to be appended to <filename>/etc/nix/nix.conf</filename>.";
      };

      checkConfig = mkOption {
        type = types.bool;
        default = true;
        description = ''
          If enabled, checks that Nix can parse the generated nix.conf.
        '';
      };

      checkAllErrors = mkOption {
        type = types.bool;
        default = true;
        description = ''
          If enabled, checks the nix.conf parsing for any kind of error. When disabled, checks only for unknown settings.
        '';
      };

      settings = mkOption {
        type = types.submodule {
          freeformType = semanticConfType;

          options = {
            substituters = mkOption {
              type = types.listOf types.str;
              description = ''
                A list of URLs of substituters.  The official NixOS and Nix-on-Droid
                substituters are added by default.
              '';
            };

            trusted-public-keys = mkOption {
              type = types.listOf types.str;
              description = ''
                A list of public keys.  When paths are copied from another Nix store (such as a
                binary cache), they must be signed with one of these keys.  The official NixOS
                and Nix-on-Droid public keys are added by default.
              '';
            };
          };
        };
        default = { };
        example = literalExpression ''
          {
            experimental-fetures = [ "nix-commnd" "flake" ];
          }
        '';
        description = ''
          Configuration for Nix, see
          <link xlink:href="https://nixos.org/manual/nix/stable/#sec-conf-file"/> or
          <citerefentry>
            <refentrytitle>nix.conf</refentrytitle>
            <manvolnum>5</manvolnum>
          </citerefentry> for available options.
          The value declared here will be translated directly to the key-value pairs Nix expects.
          </para>
          <para>
          Nix configurations defined under <option>nix.*</option> will be translated and applied to this
          option. In addition, configuration specified in <option>nix.extraOptions</option> will be appended
          verbatim to the resulting config file.
        '';
      };
    };

  };


  ###### implementation

  config = mkMerge [
    {
      environment.etc = {
        "nix/nix.conf".source = nixConf;
        "nix/registry.json".text = builtins.toJSON {
          version = 2;
          flakes = mapAttrsToList (_n: v: { inherit (v) from to exact; }) cfg.registry;
        };
      };

      nix.settings = {
        sandbox = false;
        substituters = [
          "https://cache.nixos.org"
          "https://nix-on-droid.cachix.org"
        ];
        trusted-public-keys = [
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
