# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ stdenv
, fetchFromGitHub
, talloc
, static ? true
, outputBinaryName ? "proot-static"
}:

stdenv.mkDerivation {
  pname = "proot-termux";
  version = "28baec5ac3e0f26c03cf2a4cdc094c9328bd5b20";

  src = fetchFromGitHub {
    repo = "proot";
    owner = "termux";
    rev = "28baec5ac3e0f26c03cf2a4cdc094c9328bd5b20";
    sha256 = "sha256-TMYkLmk+NnYcqJKF6RSOkN4S8AI5+HaNcgZZe/5E0vI=";
  };

  # ashmem.h is rather small, our needs are even smaller, so just define these:
  preConfigure = ''
    mkdir -p fake-ashmem/linux; cat > fake-ashmem/linux/ashmem.h << EOF
    #include <linux/limits.h>
    #include <sys/ioctl.h>
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
  CFLAGS = [
    "-O3" "-I../fake-ashmem"
    "-D_LARGEFILE64_SOURCE" "-DMSG_COPY=040000" "-DTEMP_FAILURE_RETRY="
    "-D__ANDROID__"
    # Copied from linux/include/uapi/asm-generic/ioctls.h
    "-DTCGETS=0x5401"
    "-DTCSETS=0x5402"
    "-DTCSETSW=0x5403"
    "-DTCSETSF=0x5404"
    "-DTCGETS2=0x802C542A"
    "-DTCSETS2=0x402C542B"
    "-DTCSETSW2=0x402C542C"
    "-DTCSETSF2=0x402C542D"
  ] ++
    (if static then [ "-static" ] else [ ]);
  LDFLAGS = if static then [ "-static" ] else [ ];
  preInstall = "${stdenv.cc.targetPrefix}strip src/proot";
  installPhase = "install -D -m 0755 src/proot $out/bin/${outputBinaryName}";
}
