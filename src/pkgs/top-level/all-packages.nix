# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ config, lib, nixpkgs }:

let
  callPackage = nixpkgs.lib.callPackageWith (
    nixpkgs // pkgs // {
      inherit callPackage;

      config = nixpkgs.config // config;

      lib = nixpkgs.lib // lib;
    }
  );

  pkgs = rec {

    # files

    files = callPackage ../files { } // { recurseForDerivations = true; };

    # initial build

    bootstrap = callPackage ../initial-build/bootstrap.nix { };

    bootstrapZip = callPackage ../initial-build/bootstrap-zip.nix { };

    nixDirectory = callPackage ../initial-build/nix-directory.nix { };

    packageInfo = import "${nixDirectory}/nix-support/package-info.nix";

    prootTermux = callPackage ../initial-build/cross-compiling/proot-termux.nix { };

    qemuAarch64Static = callPackage ../initial-build/qemu-aarch64-static.nix { };

    talloc = callPackage ../initial-build/cross-compiling/talloc.nix { };

  };
in

pkgs
