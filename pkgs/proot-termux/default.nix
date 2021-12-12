# Copyright (c) 2019-2021, see AUTHORS. Licensed under MIT License, see LICENSE.

{ pkgs, stdenv, callPackage, fetchFromGitHub,
  talloc, outputBinaryName ? "proot-static" }:

stdenv.mkDerivation {
  pname = "proot-termux";
  version = "unstable-2021-11-21";

  src = fetchFromGitHub {
    repo = "proot";
    owner = "termux";
    rev = "7d6bdd9f6cf31144e11ce65648dab2a1e495a7de";
    sha256 = "sha256-sbueMoqhOw0eChgp6KOZbhwRnSmDZhHq+jm06mGqxC4=";

    # 1 step behind 6f12fbee "Implement shmat", use if ashmem.h is missing
    #rev = "ffd811ee726c62094477ed335de89fc107cadf17";
    #sha256 = "1zjblclsybvsrjmq2i0z6prhka268f0609w08dh9vdrbrng117f8";
  };

  buildInputs = [ talloc ];

  patches = [ ./detranslate-empty.patch ];

  makeFlags = [ "-Csrc" "V=1" ];
  CFLAGS = [ "-O3" ];

  installPhase = ''
    install -D -m 0755 src/proot $out/bin/${outputBinaryName}
  '';
}
