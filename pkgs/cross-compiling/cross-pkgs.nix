# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ callPackage, nixpkgs }:

let
  args = callPackage ./cross-pkgs-args.nix { };
  pkgsCross-imported = import nixpkgs args;
  pkgsCross-patched = pkgsCross-imported.applyPatches {
    name = "nixpkgs-crosscompilation-patched";
    src = nixpkgs;
    patches = [ ./compiler-rt.patch ];
    postPatch = ''
      substituteInPlace pkgs/development/compilers/llvm/common/compiler-rt/default.nix \
        --replace-fail 'ln -s $out/lib/*/clang_rt.crtbegin-*.o $out/lib/crtbeginS.o' "" \
        --replace-fail 'ln -s $out/lib/*/clang_rt.crtend-*.o $out/lib/crtendS.o' "" \
        --replace-fail '"dev"' ""
       sed -i '/cmakeFlags/i LDFLAGS = "-unwindlib=none";' pkgs/development/compilers/llvm/common/libunwind/default.nix
    '';
  };
  pkgsCross = import pkgsCross-patched args;
in
pkgsCross
