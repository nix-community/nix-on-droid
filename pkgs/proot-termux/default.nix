# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ stdenv
, fetchFromGitHub
, talloc
, static ? true
, outputBinaryName ? "proot-static"
,
}:

stdenv.mkDerivation {
  pname = "proot-termux";
  version = "0-unstable-2025-10-19";

  src = fetchFromGitHub {
    repo = "proot";
    owner = "termux";
    rev = "228a5f28b078f4e2504de46758ce17948f73f507";
    hash = "sha256-ViV8i7W47dEgYDKPN1w4tY+XaVHcXLWxTGTX3wKdARk=";
  };

  # ashmem.h is rather small, our needs are even smaller, so just define these:
  preConfigure = ''
    mkdir --parents fake-ashmem/linux
    cat > fake-ashmem/linux/ashmem.h << EOF
    #include <linux/limits.h>
    #include <linux/ioctl.h>
    #include <string.h>
    #define __ASHMEMIOC 0x77
    #define ASHMEM_NAME_LEN 256
    #define ASHMEM_SET_NAME _IOW(__ASHMEMIOC, 1, char[ASHMEM_NAME_LEN])
    #define ASHMEM_SET_SIZE _IOW(__ASHMEMIOC, 3, size_t)
    #define ASHMEM_GET_SIZE _IO(__ASHMEMIOC, 4)
    EOF
    substituteInPlace src/arch.h \
      --replace-fail '#define HAS_LOADER_32BIT true' ""
    ! (grep -F '#define HAS_LOADER_32BIT' src/arch.h)
  '';
  buildInputs = [ talloc ];
  patches = [ ./detranslate-empty.patch ];
  makeFlags = [
    "-Csrc"
    "V=1"
  ];
  CFLAGS = [
    "-O3"
    "-I../fake-ashmem"
  ]
  ++ (if static then [ "-static" ] else [ ]);
  LDFLAGS = if static then [ "-static" ] else [ ];
  installPhase = ''
    runHook preInstall

    ${stdenv.cc.targetPrefix}strip src/proot
    install -D --mode=0755 src/proot $out/bin/${outputBinaryName}

    runHook postInstall
  '';
}
