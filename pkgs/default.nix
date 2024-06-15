# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ nixpkgs
, system
, arch ? "aarch64"
, nixOnDroidChannelURL ? null
, nixpkgsChannelURL ? null
, nixOnDroidFlakeURL ? null
}:

let
  nixDirectory = callPackage ./nix-directory.nix { };
  initialPackageInfo = import "${nixDirectory}/nix-support/package-info.nix";

  pkgs = import nixpkgs { inherit system; };

  urlOptionValue = url: envVar:
    let
      envValue = builtins.getEnv envVar;
    in
    pkgs.lib.mkIf
      (envValue != "" || url != null)
      (if url == null then envValue else url);

  modules = import ../modules {
    inherit pkgs;

    isFlake = true;

    config = {
      imports = [ ../modules/build/initial-build.nix ];

      _module.args = {
        inherit initialPackageInfo;
        pkgs = pkgs.lib.mkForce pkgs; # to override ./modules/nixpkgs/config.nix
      };

      system.stateVersion = "23.11";

      # Fix invoking bash after initial build.
      user.shell = "${initialPackageInfo.bash}/bin/bash";

      build = {
        arch =
          if arch != null
          then arch
          else nixpkgs.lib.strings.removeSuffix "-linux" builtins.currentSystem;

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
