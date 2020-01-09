# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, lib, pkgs, ... }:

with lib;

{

  ###### interface

  options = {

    build.channel = {
      nixpkgs = mkOption {
        type = types.str;
        default = "https://nixos.org/channels/nixos-19.09";
        description = "Channel URL for nixpkgs.";
      };

      nix-on-droid = mkOption {
        type = types.str;
        default = "https://github.com/t184256/nix-on-droid-bootstrap/archive/master.tar.gz";
        description = "Channel URL for nix-on-droid.";
      };
    };

  };


  ###### implementation

  config = {

    build.initialBuild = true;

    # /etc/group and /etc/passwd need to be build on target machine because
    # uid and gid need to be determined.
    environment.etc = {
      "group".enable = false;
      "passwd".enable = false;
      "UNINTIALISED".text = "";
    };

  };

}
