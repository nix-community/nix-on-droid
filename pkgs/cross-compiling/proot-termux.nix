# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

{ callPackage, fetchFromGitHub, tallocStatic }:

let
  pkgs = callPackage ./pkgs.nix { };
in

pkgs.crossStatic.stdenv.mkDerivation {
  pname = "proot-termux";
  version = "unstable-2020-04-25";

  src = fetchFromGitHub {
    repo = "proot";
    owner = "termux";
    rev = "b9588b1edff5069118c50f2f9b19397fce39f5c7";
    sha256 = "0izs2vqbn7zaa0fxwr78p1kaa4f3k9rhv4g94zsmw38cqlmidv56";
  };

  buildInputs = [ tallocStatic ];

  makeFlags = [ "-Csrc CFLAGS=-D__ANDROID__" ];

  installPhase = ''
    install -D -m 0755 src/proot $out/bin/proot-static
  '';
}
