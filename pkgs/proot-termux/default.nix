# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ stdenv
, fetchFromGitHub
, talloc
, static ? true
, outputBinaryName ? "proot-static"
}:

stdenv.mkDerivation {
  pname = "proot-termux";
  version = "0-unstable-2026-01-18";

  src = fetchFromGitHub {
    repo = "proot";
    owner = "termux";
    rev = "4dba3afbf3a63af89b4d9c1a59bf2bda10f4d10f";
    hash = "sha256-NnlAvv8b0MKEX2BlD1GRpzoWCpgJxiIEgJ9C+C0PrMw=";
  };

  # ashmem.h is rather small, our needs are even smaller, so just define these:
  preConfigure = ''
    mkdir -p fake-ashmem/linux; cat > fake-ashmem/linux/ashmem.h << EOF
    #include <linux/limits.h>
    #include <linux/ioctl.h>
    #include <string.h>
    #define __ASHMEMIOC 0x77
    #define ASHMEM_NAME_LEN 256
    #define ASHMEM_SET_NAME _IOW(__ASHMEMIOC, 1, char[ASHMEM_NAME_LEN])
    #define ASHMEM_SET_SIZE _IOW(__ASHMEMIOC, 3, size_t)
    #define ASHMEM_GET_SIZE _IO(__ASHMEMIOC, 4)
    EOF
    substituteInPlace src/arch.h --replace \
      '#define HAS_LOADER_32BIT true' \
      ""
    ! (grep -F '#define HAS_LOADER_32BIT' src/arch.h)
  '';
  buildInputs = [ talloc ];
  patches = [ ./detranslate-empty.patch ];
  makeFlags = [ "-Csrc" "V=1" ];
  CFLAGS = [ "-O3" "-I../fake-ashmem" ] ++
    (if static then [ "-static" ] else [ ]);
  LDFLAGS = if static then [ "-static" ] else [ ];
  preInstall = "${stdenv.cc.targetPrefix}strip src/proot";
  installPhase = "install -D -m 0755 src/proot $out/bin/${outputBinaryName}";
}
