# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

{ arch, nixOnDroidChannelURL ? null, nixpkgsChannelURL ? null }:

let
  loadNixpkgs = import lib/load-nixpkgs.nix;

  nixDirectory = callPackage ./nix-directory.nix { };
  packageInfo = import "${nixDirectory}/nix-support/package-info.nix";

  nixpkgs = loadNixpkgs { };

  modules = import ../modules {
    pkgs = nixpkgs;

    config = {
      # Fix invoking bash after initial build.
      user.shell = "${packageInfo.bash}/bin/bash";

      imports = [ ../modules/build/initial-build.nix ];

      _module.args = { inherit customPkgs; };

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
      inherit callPackage;
    }
  );

  customPkgs = rec {
    inherit nixDirectory packageInfo;
    bootstrap = callPackage ./bootstrap.nix { };
    bootstrapZip = callPackage ./bootstrap-zip.nix { };
    prootTermux = callPackage ./cross-compiling/proot-termux.nix { };
    qemuAarch64Static = callPackage ./qemu-aarch64-static.nix { };
    tallocStatic = callPackage ./cross-compiling/talloc-static.nix { };
  };
in

customPkgs
