# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ config, lib, pkgs, ... }:

with lib;

{

  ###### interface

  options = {

    build = {
      arch = mkOption {
        type = types.enum [ "aarch64" "i686" ];
        description = "Destination arch.";
      };

      channel = {
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

  };


  ###### implementation

  config = {

    build.initialBuild = true;

    # /etc/group and /etc/passwd need to be build on target machine because
    # uid and gid need to be determined.
    environment.etc = {
      "group".enable = false;
      "nix-on-droid.nix.default".text = builtins.readFile ./nix-on-droid.nix.default;
      "passwd".enable = false;
    };

  };

}
