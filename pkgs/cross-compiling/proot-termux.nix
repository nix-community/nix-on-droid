# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

{ callPackage, tallocStatic, applyPatches, fetchFromGitHub }:

let
  args = callPackage ./cross-pkgs-args.nix { };
  pkgsCross = import
    (applyPatches {
      name = "nixpkgs-crosscompilation-patched";
      src = fetchFromGitHub {
        owner = "NixOS";
        repo = "nixpkgs";
        rev = "49ee0e94463abada1de470c9c07bfc12b36dcf40";
        hash = "sha256-WrDV0FPMVd2Sq9hkR5LNHudS3OSMmUrs90JUTN+MXpA=";
      };
      postPatch = ''
        substituteInPlace pkgs/development/compilers/llvm/common/compiler-rt/default.nix \
          --replace-fail 'ln -s $out/lib/*/clang_rt.crtbegin-*.o $out/lib/crtbeginS.o' "" \
          --replace-fail 'ln -s $out/lib/*/clang_rt.crtend-*.o $out/lib/crtendS.o' "" \
          --replace-fail '"dev"' ""
         sed -i '/cmakeFlags/i LDFLAGS = "-unwindlib=none";' pkgs/development/compilers/llvm/common/libunwind/default.nix
      '';
    })
    args;

  stdenv = pkgsCross.stdenvAdapters.makeStaticBinaries pkgsCross.stdenv;
in

pkgsCross.callPackage ../proot-termux {
  talloc = tallocStatic;
  inherit stdenv;
}
