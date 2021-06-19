# Copyright (c) 2019-2021, see AUTHORS. Licensed under MIT License, see LICENSE.

{ callPackage, fetchFromGitHub, tallocStatic }:

let
  pkgs = callPackage ./pkgs.nix { };
in

pkgs.crossStatic.stdenv.mkDerivation {
  pname = "proot-termux";
  version = "unstable-2021-05-19";

  src = fetchFromGitHub {
    repo = "proot";
    owner = "termux";
    rev = "3b7369b8eb8b2a879aade2b403b3ac0eb848b9ed";  # the one with make fix
    sha256 = "1wrrar08axfwrma7yp2zlf61cz4crypr3m1jnhkqng7p1pry1cay";

    # 1 step behind 6f12fbee "Implement shmat", use if ashmem.h is missing
    #rev = "ffd811ee726c62094477ed335de89fc107cadf17";
    #sha256 = "1zjblclsybvsrjmq2i0z6prhka268f0609w08dh9vdrbrng117f8";

  };

  buildInputs = [ tallocStatic ];

  patches = [ ./proot-detranslate-empty.patch ];

  makeFlags = [ "-Csrc" "V=1" ];

  installPhase = ''
    install -D -m 0755 src/proot $out/bin/proot-static
  '';
}
