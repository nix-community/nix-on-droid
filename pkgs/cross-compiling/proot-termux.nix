# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

{ callPackage, nixpkgs, tallocStatic }:

let
  pkgsCross = import nixpkgs (callPackage ./cross-pkgs-args.nix { });
  stdenv = pkgsCross.stdenvAdapters.makeStaticBinaries pkgsCross.stdenv;
in

pkgsCross.callPackage ../proot-termux {
  talloc = tallocStatic;
  inherit stdenv;
}
