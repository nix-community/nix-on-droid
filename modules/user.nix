# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.user;

  idsDerivation = pkgs.runCommandLocal "ids.nix" { } ''
    cat > $out <<EOF
    {
      gid = $(${pkgs.coreutils}/bin/id -g);
      uid = $(${pkgs.coreutils}/bin/id -u);
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

      gid = mkOption {
        type = types.int;
        default = ids.gid;
        defaultText = "$(id -g)";
        description = ''
          Gid.  This value should not be set manually except you know what you are doing.
        '';
      };

      home = mkOption {
        type = types.path;
        readOnly = true;
        description = "Path to home directory.";
      };

      shell = mkOption {
        type = types.path;
        default = "${pkgs.bashInteractive}/bin/bash";
        defaultText = literalExpression "${pkgs.bashInteractive}/bin/bash";
        description = "Path to login shell.";
      };

      userName = mkOption {
        type = types.str;
        readOnly = true;
        description = "User name.";
      };

      uid = mkOption {
        type = types.int;
        default = ids.uid;
        defaultText = "$(id -u)";
        description = ''
          Uid.  This value should not be set manually except you know what you are doing.
        '';
      };
    };

  };


  ###### implementation

  config = {

    environment.etc = {
      "group".text = ''
        root:x:0:
        ${cfg.group}:x:${toString cfg.gid}:${cfg.userName}
      '';

      "passwd".text = ''
        root:x:0:0:System administrator:${config.build.installationDir}/root:/bin/sh
        ${cfg.userName}:x:${toString cfg.uid}:${toString cfg.gid}:${cfg.userName}:${cfg.home}:${cfg.shell}
      '';
    };

    user = {
      group = "nix-on-droid";
      home = "/data/data/com.termux/files/home";
      userName = "nix-on-droid";
    };

  };

}
