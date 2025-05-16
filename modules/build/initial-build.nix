# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, lib, pkgs, ... }:

with lib;

let
  defaultNixpkgsBranch = "nixos-24.11";
  defaultNixOnDroidBranch = "release-24.11";

  defaultNixpkgsChannel = "https://nixos.org/channels/${defaultNixpkgsBranch}";
  defaultNixOnDroidChannel = "https://github.com/nix-community/nix-on-droid/archive/${defaultNixOnDroidBranch}.tar.gz";

  defaultNixpkgsFlake = "github:NixOS/nixpkgs/${defaultNixpkgsBranch}";
  defaultNixOnDroidFlake = "github:nix-community/nix-on-droid/${defaultNixOnDroidBranch}";
in

{

  ###### interface

  options = {

    build = {
      channel = {
        nixpkgs = mkOption {
          type = types.str;
          default = defaultNixpkgsChannel;
          description = "Channel URL for nixpkgs.";
        };

        nix-on-droid = mkOption {
          type = types.str;
          default = defaultNixOnDroidChannel;
          description = "Channel URL for Nix-on-Droid.";
        };
      };

      flake = {
        nixpkgs = mkOption {
          type = types.str;
          default = defaultNixpkgsFlake;
          description = "Flake URL for nixpkgs.";
        };

        nix-on-droid = mkOption {
          type = types.str;
          default = defaultNixOnDroidFlake;
          description = "Flake URL for Nix-on-Droid.";
        };

        inputOverrides = mkEnableOption "" // {
          description = ''
            Whether to override the standard input URLs in the initial <filename>flake.nix</filename>.
          '';
        };
      };
    };

  };


  ###### implementation

  config = {

    build = {
      initialBuild = true;

      flake.inputOverrides =
        config.build.flake.nixpkgs != defaultNixpkgsFlake
        || config.build.flake.nix-on-droid != defaultNixOnDroidFlake;
    };

    # /etc/group and /etc/passwd need to be build on target machine because
    # uid and gid need to be determined.
    environment.etc = {
      "group".enable = false;
      "passwd".enable = false;
      "UNINTIALISED".text = "";
    };

  };

}
