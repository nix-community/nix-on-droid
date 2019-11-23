# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ callPackage, fetchurl, python2, zlib }:

let
  pkgs = callPackage ./pkgs.nix { };
in

pkgs.cross.stdenv.mkDerivation rec {
  name = "talloc-2.1.14";

  src = fetchurl {
    url = "mirror://samba/talloc/${name}.tar.gz";
    sha256 = "1kk76dyav41ip7ddbbf04yfydb4jvywzi2ps0z2vla56aqkn11di";
  };

  depsBuildBuild = [ python2 zlib ];

  buildDeps = [ pkgs.cross.zlib ];

  configurePhase = ''
    substituteInPlace buildtools/bin/waf \
      --replace "/usr/bin/env python" "${python2}/bin/python"
    ./configure --prefix=$out \
      --disable-rpath \
      --disable-python \
      --cross-compile \
      --cross-answers=cross-answers.txt
  '';

  buildPhase = ''
    make
  '';

  installPhase = ''
    mkdir -p $out/lib
    make install
    ${pkgs.cross.stdenv.cc.targetPrefix}ar q $out/lib/libtalloc.a bin/default/talloc_[0-9]*.o
  '';

  fixupPhase = "";

  prePatch = ''
    cat <<EOF > cross-answers.txt
    Checking uname sysname type: "Linux"
    Checking uname machine type: "dontcare"
    Checking uname release type: "dontcare"
    Checking uname version type: "dontcare"
    Checking simple C program: OK
    building library support: OK
    Checking for large file support: OK
    Checking for -D_FILE_OFFSET_BITS=64: OK
    Checking for WORDS_BIGENDIAN: OK
    Checking for C99 vsnprintf: OK
    Checking for HAVE_SECURE_MKSTEMP: OK
    rpath library support: OK
    -Wl,--version-script support: FAIL
    Checking correct behavior of strtoll: OK
    Checking correct behavior of strptime: OK
    Checking for HAVE_IFACE_GETIFADDRS: OK
    Checking for HAVE_IFACE_IFCONF: OK
    Checking for HAVE_IFACE_IFREQ: OK
    Checking getconf LFS_CFLAGS: OK
    Checking for large file support without additional flags: OK
    Checking for working strptime: OK
    Checking for HAVE_SHARED_MMAP: OK
    Checking for HAVE_MREMAP: OK
    Checking for HAVE_INCOHERENT_MMAP: OK
    Checking getconf large file support flags work: OK
    EOF
  '';
}
