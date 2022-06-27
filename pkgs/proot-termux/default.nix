# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

{ pkgs, stdenv, callPackage, fetchFromGitHub,
  talloc, outputBinaryName ? "proot-static" }:

stdenv.mkDerivation {
  pname = "proot-termux";
  version = "unstable-2022-05-03";

  src = fetchFromGitHub {
    repo = "proot";
    owner = "termux";
    rev = "5c462a6ecfddd629b1439f38fbb61216d6fcb359";
    sha256 = "sha256-XS4js80NsAN2C4jMuISSqMm/DwYpH/stbABaxzoqZcE=";

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
