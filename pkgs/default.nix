# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

{ nixpkgs
, system
, arch ? "aarch64"
, nixOnDroidChannelURL ? null
, nixpkgsChannelURL ? null
}:

let
  nixDirectory = callPackage ./nix-directory.nix { };
  initialPackageInfo = import "${nixDirectory}/nix-support/package-info.nix";

  pkgs = import nixpkgs { inherit system; };

  modules = import ../modules {
    inherit pkgs;

    extraModules = [ ../modules/build/initial-build.nix ];
    extraSpecialArgs = {
      inherit initialPackageInfo;
      pkgs = pkgs.lib.mkForce pkgs; # to override ./modules/nixpkgs/config.nix
    };

    isFlake = true;

    config = {
      # Fix invoking bash after initial build.
      user.shell = "${initialPackageInfo.bash}/bin/bash";

      build = {
        inherit arch;

        channel = with pkgs.lib; {
          nixpkgs = mkIf (nixpkgsChannelURL != null) nixpkgsChannelURL;
          nix-on-droid = mkIf (nixOnDroidChannelURL != null) nixOnDroidChannelURL;
        };
      };
    };
  };

  callPackage = pkgs.lib.callPackageWith (
    pkgs // customPkgs // {
      inherit (modules) config;
      inherit callPackage nixpkgs nixDirectory initialPackageInfo;
    }
  );

  customPkgs = {
    bootstrap = callPackage ./bootstrap.nix { };
    bootstrapZip = callPackage ./bootstrap-zip.nix { };
    prootTermux = callPackage ./cross-compiling/proot-termux.nix { };
    tallocStatic = callPackage ./cross-compiling/talloc-static.nix { };
    prootTermuxTest = callPackage ./proot-termux {
      inherit (pkgs) stdenv;
      static = false;
      outputBinaryName = "proot";
    };
  };
in

{
  inherit (modules) config;
  inherit customPkgs;
}
