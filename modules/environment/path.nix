# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

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
        default = [];
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
      $DRY_RUN_CMD nix-env --install ${cfg.path}
    '';

    environment = {
      packages = [
        (pkgs.callPackage ../../nix-on-droid { })
        pkgs.bashInteractive
        pkgs.cacert
        pkgs.coreutils
        pkgs.less  # since nix tools really want a pager available, #27
        pkgs.nix
      ];

      path = pkgs.buildEnv {
        name = "nix-on-droid-path";

        paths = cfg.packages;

        meta = {
          description = "Environment of packages installed through nix-on-droid.";
        };
      };
    };

  };

}
