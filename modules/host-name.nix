# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.networking;
in

{

  ###### interface

  options = {

    networking.hostName = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "The name of the machine.";
    };

  };


  ###### implementation

  config = mkIf (cfg.hostName != null) {

    build.activation.hostname = ''
      ${pkgs.nettools}/bin/hostname "${cfg.hostName}"
    '';

    environment.etc."hostname".text = cfg.hostName + "\n";

  };

}
