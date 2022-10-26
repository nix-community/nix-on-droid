# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.environment;
in

{

  ###### interface

  options = {

    environment = {
      packages = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = "List of packages to be installed as user packages.";
      };

      path = mkOption {
        type = types.package;
        readOnly = true;
        internal = true;
        description = "Derivation for installing user packages.";
      };
    };

  };


  ###### implementation

  config = {

    build.activation.installPackages = ''
      if [[ -e "${config.user.home}/.nix-profile/manifest.json" ]]; then
        $DRY_RUN_CMD nix profile install ${cfg.path}
      else
        $DRY_RUN_CMD nix-env --install ${cfg.path}
      fi
    '';

    environment = {
      packages = [
        (pkgs.callPackage ../../nix-on-droid { nix = config.nix.package; })
        pkgs.bashInteractive
        pkgs.cacert
        pkgs.coreutils
        pkgs.less # since nix tools really want a pager available, #27
        config.nix.package
      ];

      path = pkgs.buildEnv {
        name = "nix-on-droid-path";

        paths = cfg.packages;

        meta = {
          description = "Environment of packages installed through Nix-on-Droid.";
        };
      };
    };

  };

}
