# Copyright (c) 2019-2021, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, lib, pkgs, ... }:

with lib;

{

  ###### interface

  options = {

    build.channel = {
      nixpkgs = mkOption {
        type = types.str;
        default = "https://nixos.org/channels/nixos-21.11";
        description = "Channel URL for nixpkgs.";
      };

      nix-on-droid = mkOption {
        type = types.str;
        default = "https://github.com/t184256/nix-on-droid/archive/release-21.11.tar.gz";
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
