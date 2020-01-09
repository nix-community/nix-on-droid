# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.user;

  idsDerivation = pkgs.runCommand "ids.nix" {} ''
    cat > $out <<EOF
    {
      gid = "$(${pkgs.coreutils}/bin/id -g)";
      uid = "$(${pkgs.coreutils}/bin/id -u)";
    }
    EOF
  '';

  ids = import idsDerivation;
in

{

  ###### interface

  options = {

    user = {
      group = mkOption {
        type = types.str;
        readOnly = true;
        description = "Group name.";
      };

      home = mkOption {
        type = types.path;
        readOnly = true;
        description = "Path to home directory.";
      };

      shell = mkOption {
        type = types.path;
        readOnly = true;
        description = "Path to login shell.";
      };

      userName = mkOption {
        type = types.str;
        readOnly = true;
        description = "User name.";
      };
    };

  };


  ###### implementation

  config = {

    environment.etc = {
      "group".text = ''
        root:x:0:
        ${cfg.group}:x:${ids.gid}:${cfg.userName}
      '';

      "passwd".text = ''
        root:x:0:0:System administrator:${config.build.installationDir}/root:/bin/sh
        ${cfg.userName}:x:${ids.uid}:${ids.gid}:${cfg.userName}:${cfg.home}:${cfg.shell}
      '';
    };

    user = {
      group = "nix-on-droid";
      home = "/data/data/com.termux.nix/files/home";
      shell = "/bin/sh";
      userName = "nix-on-droid";
    };

  };

}
