# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ callPackage, nixpkgs }:

let
  args = callPackage ./cross-pkgs-args.nix { };
  pkgsCross-imported = import nixpkgs args;
  pkgsCross-patched = pkgsCross-imported.applyPatches {
    name = "nixpkgs-crosscompilation-patched";
    src = nixpkgs;
    patches = [
      ./compiler-rt.patch
      ./libunwind.patch
    ];
  };
  pkgsCross = import pkgsCross-patched args;
in
pkgsCross
