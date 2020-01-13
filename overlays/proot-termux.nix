# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

self: super:

let
  nixpkgs = import ./lib/nixpkgs.nix { inherit super; };

  talloc-static = nixpkgs.stdenv.mkDerivation rec {
    name = "talloc-2.1.14";

    src = nixpkgs.fetchurl {
      url = "mirror://samba/talloc/${name}.tar.gz";
      sha256 = "1kk76dyav41ip7ddbbf04yfydb4jvywzi2ps0z2vla56aqkn11di";
    };

    depsBuildBuild = [ nixpkgs.python2 nixpkgs.zlib ];

    buildDeps = [ nixpkgs.zlib ];

    configurePhase = ''
      substituteInPlace buildtools/bin/waf \
        --replace "/usr/bin/env python" "${nixpkgs.python2}/bin/python"
      ./configure --prefix=$out \
        --disable-rpath \
        --disable-python \
    '';

    buildPhase = ''
      make
    '';

    installPhase = ''
      mkdir -p $out/lib
      make install
      gcc-ar q $out/lib/libtalloc.a bin/default/talloc_[0-9]*.o
      rm -f $out/lib/libtalloc.so*
    '';

    fixupPhase = "";
  };
in

{
  proot-termux = nixpkgs.stdenv.mkDerivation rec {
    pname = "proot-termux";
    version = "unstable-2019-09-05";

    src = nixpkgs.fetchFromGitHub {
      repo = "proot";
      owner = "termux";
      rev = "3ea655b1ae40bfa2ee612d45bf1e7ad97c4559f8";
      sha256 = "05y30ifbp4sn1pzy8wlifc5d9n2lrgspqzdjix1kxjj9j9947qgd";
    };

    buildInputs = [ talloc-static nixpkgs.llvm nixpkgs.glibc.static ];

    CC = "llvm";
    CFLAGS = "-D__ANDROID__";
    LDFLAGS = "-static";
    makeFlags = [ "-Csrc CFLAGS=-D__ANDROID__" ];

    installPhase = ''
      install -D -m 0755 src/proot $out/bin/proot-static
    '';

    fixupPhase = "";
  };
}
