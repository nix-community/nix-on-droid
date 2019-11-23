# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.environment;
in

{

  ###### interface

  options = {

    environment = {
      binSh = mkOption {
        type = types.str;
        readOnly = true;
        description = "Path to /bin/sh executable.";
      };

      usrBinEnv = mkOption {
        type = types.str;
        readOnly = true;
        description = "Path to /usr/bin/env executable.";
      };
    };

  };


  ###### implementation

  config = {

    build.activation = {
      linkBinSh = ''
        $DRY_RUN_CMD mkdir $VERBOSE_ARG --parents /bin
        $DRY_RUN_CMD ln $VERBOSE_ARG --symbolic --force ${cfg.binSh} /bin/.sh.tmp
        $DRY_RUN_CMD mv $VERBOSE_ARG /bin/.sh.tmp /bin/sh
      '';

      linkUsrBinEnv = ''
        $DRY_RUN_CMD mkdir $VERBOSE_ARG --parents /usr/bin
        $DRY_RUN_CMD ln $VERBOSE_ARG --symbolic --force ${cfg.usrBinEnv} /usr/bin/.env.tmp
        $DRY_RUN_CMD mv $VERBOSE_ARG /usr/bin/.env.tmp /usr/bin/env
      '';
    };

    environment = {
      binSh = "${pkgs.bashInteractive}/bin/sh";
      usrBinEnv = "${pkgs.coreutils}/bin/env";
    };

  };

}
