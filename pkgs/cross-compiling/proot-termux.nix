# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

{ callPackage, fetchFromGitHub, tallocStatic }:

let
  pkgs = callPackage ./pkgs.nix { };
in

pkgs.crossStatic.stdenv.mkDerivation {
  pname = "proot-termux";
  version = "unstable-2020-10-25";

  src = fetchFromGitHub {
    repo = "proot";
    owner = "termux";
    rev = "66b34c6fb38983b09da3400b8bcf86005ebe8dd1";
    sha256 = "0isrjcblkdkikw6l6f7a2p326vsy3plbs9ga48r20lpa8rsz4jnf";
  };

  buildInputs = [ tallocStatic ];

  patches = [ ./proot-detranslate-empty.patch ];

  makeFlags = [ "-Csrc CFLAGS=-D__ANDROID__" ];

  installPhase = ''
    install -D -m 0755 src/proot $out/bin/proot-static
  '';
}
