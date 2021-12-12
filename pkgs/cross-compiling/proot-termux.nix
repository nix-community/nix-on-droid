# Copyright (c) 2019-2021, see AUTHORS. Licensed under MIT License, see LICENSE.

{ callPackage, tallocStatic }:

let
  pkgsCross = callPackage ./cross-pkgs.nix { };

  stdenv = pkgsCross.pkgsStatic.stdenvAdapters.makeStaticBinaries pkgsCross.stdenv;

in
  callPackage ../proot-termux {
    pkgs = pkgsCross;
    talloc = tallocStatic;
    inherit stdenv;
  }
