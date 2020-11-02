# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

{ callPackage, fetchurl, python3, wafHook }:

let
  pkgs = callPackage ./pkgs.nix { };
in

pkgs.cross.talloc.overrideAttrs (old: rec {
  pname = "talloc-static";
  version = "2.1.14";
  name = "${pname}-${version}";

  nativeBuildInputs = [ python3 wafHook ];
  buildInputs = [];

  wafPath = "./buildtools/bin/waf";
  wafConfigureFlags = [
      "--disable-rpath"
      "--disable-python"
      "--cross-compile"
      "--cross-answers=cross-answers.txt"
  ];

  postInstall = ''
    ${pkgs.cross.stdenv.cc.targetPrefix}ar q $out/lib/libtalloc.a bin/default/talloc.c.[0-9]*.o
    rm -f $out/lib/libtalloc.so*
  '';

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
})
