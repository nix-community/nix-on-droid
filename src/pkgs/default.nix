# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ arch, buildPkgs, crossPkgs, crossStaticPkgs, initialBuild, pinnedPkgs } @ args:

let
  callPackage = buildPkgs.lib.callPackageWith (args // pkgs);

  pkgs = rec {
    bootstrap = callPackage ./bootstrap.nix { };

    bootstrapZip = callPackage ./bootstrap-zip.nix { };

    files = callPackage ./files { } // { recurseForDerivations = true; };

    nixDirectory = callPackage ./nix-directory.nix { };

    proot = callPackage ./proot.nix { };

    qemuAarch64Static = callPackage ./qemu-aarch64-static.nix { };

    talloc = callPackage ./talloc.nix { };
  };
in

pkgs
