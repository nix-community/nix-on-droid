# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ nixpkgs
, system  # system to compile for, user-facing name of targetSystem
, _nativeSystem ? null  # system to cross-compile from, see flake.nix
, nixOnDroidChannelURL ? null
, nixpkgsChannelURL ? null
, nixOnDroidFlakeURL ? null
}:

let
  nativeSystem = if _nativeSystem == null then system else _nativeSystem;
  nixDirectory = callPackage ./nix-directory.nix { inherit system; };
  initialPackageInfo = import "${nixDirectory}/nix-support/package-info.nix";

  pkgs = import nixpkgs { system = nativeSystem; };

  urlOptionValue = url: envVar:
    let
      envValue = builtins.getEnv envVar;
    in
    pkgs.lib.mkIf
      (envValue != "" || url != null)
      (if url == null then envValue else url);

  modules = import ../modules {
    inherit pkgs;
    targetSystem = system;

    isFlake = true;

    config = {
      imports = [ ../modules/build/initial-build.nix ];

      _module.args = {
        inherit initialPackageInfo;
        pkgs = pkgs.lib.mkForce pkgs; # to override ./modules/nixpkgs/config.nix
      };

      system.stateVersion = "24.05";

      # Fix invoking bash after initial build.
      user.shell = "${initialPackageInfo.bash}/bin/bash";

      environment.files.prootStatic = pkgs.lib.mkForce customPkgs.prootTermux;

      build = {
        channel = {
          nixpkgs = urlOptionValue nixpkgsChannelURL "NIXPKGS_CHANNEL_URL";
          nix-on-droid = urlOptionValue nixOnDroidChannelURL "NIX_ON_DROID_CHANNEL_URL";
        };

        flake.nix-on-droid = urlOptionValue nixOnDroidFlakeURL "NIX_ON_DROID_FLAKE_URL";
      };
    };
  };

  callPackage = pkgs.lib.callPackageWith (
    pkgs // customPkgs // {
      inherit (modules) config;
      inherit callPackage nixpkgs nixDirectory initialPackageInfo;
      targetSystem = system;
    }
  );

  customPkgs = {
    bootstrap = callPackage ./bootstrap.nix { };
    bootstrapZip = callPackage ./bootstrap-zip.nix { };
    prootTermux = callPackage ./cross-compiling/proot-termux.nix { };
    tallocStatic = callPackage ./cross-compiling/talloc-static.nix { };
  };
in

{
  inherit (modules) config;
  inherit customPkgs;
}
