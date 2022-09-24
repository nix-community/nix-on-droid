# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

{ arch ? "aarch64", nixOnDroidChannelURL ? null, nixpkgsChannelURL ? null }:

let
  nixDirectory = callPackage ./nix-directory.nix { };
  initialPackageInfo = import "${nixDirectory}/nix-support/package-info.nix";

  nixpkgs = import lib/load-nixpkgs.nix { };

  modules = import ../modules {
    pkgs = nixpkgs;

    extraModules = [ ../modules/build/initial-build.nix ];
    extraSpecialArgs = {
      inherit initialPackageInfo;
      pkgs = nixpkgs.lib.mkForce nixpkgs; # to override ./modules/nixpkgs/config.nix
    };

    config = {
      # Fix invoking bash after initial build.
      user.shell = "${initialPackageInfo.bash}/bin/bash";

      build = {
        inherit arch;

        channel = with nixpkgs.lib; {
          nixpkgs = mkIf (nixpkgsChannelURL != null) nixpkgsChannelURL;
          nix-on-droid = mkIf (nixOnDroidChannelURL != null) nixOnDroidChannelURL;
        };
      };
    };
  };

  callPackage = nixpkgs.lib.callPackageWith (
    nixpkgs // customPkgs // {
      inherit (modules) config;
      inherit callPackage nixpkgs nixDirectory initialPackageInfo;
    }
  );

  customPkgs = {
    bootstrap = callPackage ./bootstrap.nix { };
    bootstrapZip = callPackage ./bootstrap-zip.nix { };
    prootTermux = callPackage ./cross-compiling/proot-termux.nix { };
    tallocStatic = callPackage ./cross-compiling/talloc-static.nix { };
  };
in

customPkgs
