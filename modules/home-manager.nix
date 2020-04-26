# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.home-manager;

  tryEval = builtins.tryEval <home-manager/modules/modules.nix>;
  assertionNixpkgs = types ? submoduleWith;
  assertionHomeManager = tryEval.success && builtins.functionArgs (import tryEval.value) ? useNixpkgsModule;
  assertion = assertionNixpkgs && assertionHomeManager;

  extendedLib = import <home-manager/modules/lib/stdlib-extended.nix> pkgs.lib;

  hmModule = types.submoduleWith {
    specialArgs = { lib = extendedLib; };
    modules = [
      ({ name, ... }: {
        imports = import <home-manager/modules/modules.nix> {
          inherit pkgs;
          lib = extendedLib;
          useNixpkgsModule = !cfg.useGlobalPkgs;
        };

        config = {
          submoduleSupport.enable = true;
          submoduleSupport.externalPackageInstall = cfg.useUserPackages;

          home.username = config.user.userName;
          home.homeDirectory = config.user.home;
        };
      })
    ];
  };
in

{

  ###### interface

  options = {

    home-manager = {
      backupFileExtension = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "backup";
        description = ''
          On activation move existing files by appending the given
          file extension rather than exiting with an error.
        '';
      };

      config = mkOption {
        type =
          if assertion
          then types.nullOr hmModule
          else types.unspecified;
        default = null;
        description = "Home Manager configuration.";
      };

      useGlobalPkgs = mkEnableOption ''
        using the system configuration's <literal>pkgs</literal>
        argument in Home Manager. This disables the Home Manager
        options <option>nixpkgs.*</option>
      '';

      useUserPackages = mkEnableOption ''
        installation of user packages through the
        <option>environment.packages</option> option.
      '';
    };

  };


  ###### implementation

  config = mkIf (cfg.config != null) (mkMerge [

    {
      assertions = [
        {
          assertion = assertionNixpkgs;
          message = "You are currently using release-19.09 branch of nixpkgs, you need "
            + "to update to the release-20.03 channel.";
        }
        {
          assertion = assertionHomeManager;
          message = "You are currently using release-19.09 branch of home-manager, you need "
            + "to update to the release-20.03 channel.";
        }
      ];
    }

    # hack to determine if cfg.config is a valid home-manager config
    (mkIf (cfg.config ? home && cfg.config.home ? activationPackage) {

      inherit (cfg.config) assertions warnings;

      build = {
        activationBefore = mkIf cfg.useUserPackages {
          setPriorityHomeManagerPath = ''
            if nix-env -q | grep '^home-manager-path$'; then
              $DRY_RUN_CMD nix-env $VERBOSE_ARG --set-flag priority 120 home-manager-path
            fi
          '';
        };

        activationAfter.homeManager = concatStringsSep " " (
          optional
            (cfg.backupFileExtension != null)
            "HOME_MANAGER_BACKUP_EXT='${cfg.backupFileExtension}'"
          ++ [ "${cfg.config.home.activationPackage}/activate" ]
        );
      };

      environment.packages = mkIf cfg.useUserPackages cfg.config.home.packages;

    })

  ]);
}
