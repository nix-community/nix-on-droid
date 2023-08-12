# Copyright (c) 2019-2023, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, lib, pkgs, ... }:

with lib;

{

  ###### interface

  options = {

    build = {
      arch = mkOption {
        type = types.enum [ "aarch64" ];
        default = "aarch64";
        internal = true;
        description = "Destination arch.";
      };

      initialBuild = mkOption {
        type = types.bool;
        default = false;
        internal = true;
        description = ''
          Whether this is the initial build for the bootstrap zip ball.
          Should not be enabled manually, see
          <filename>initial-build.nix</filename>.
        '';
      };

      installationDir = mkOption {
        type = types.path;
        internal = true;
        readOnly = true;
        description = "Path to installation directory.";
      };

      extraProotOptions = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Extra options passed to proot, e.g., extra bind mounts.";
      };
    };

  };


  ###### implementation

  config = {

    build.installationDir = "/data/data/com.termux.nix/files/usr";

  };

}
