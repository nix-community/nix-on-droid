# Copyright (c) 2019-2025, see AUTHORS. Licensed under MIT License, see LICENSE.

{ stdenv
, fetchFromGitHub
, talloc
, static ? true
, outputBinaryName ? "proot-static"
}:

stdenv.mkDerivation {
  pname = "proot-termux";
  version = "0-unstable-2025-10-19";

  src = fetchFromGitHub {
    repo = "proot";
    owner = "termux";
    rev = "228a5f28b078f4e2504de46758ce17948f73f507";
    sha256 = "sha256-ViV8i7W47dEgYDKPN1w4tY+XaVHcXLWxTGTX3wKdARk=";
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
    # LLVM 21's lld sets file_offset = vaddr for -Ttext=0x2000000000,
    # producing an 8 GB loader binary. Adding -n (nmagic) fixes the file
    # size but sets p_align=4, which Android kernels reject (EINVAL on
    # execve). Solution: link with -n, then binary-patch p_align to
    # 0x10000 (64 KB, safe for 4/16/64 KB page-size devices).
    substituteInPlace src/GNUmakefile --replace ",-Ttext" ",-n,-Ttext"
    # Patch p_align in the first Elf64_Phdr (LOAD) of the loader ELF.
    # Elf64_Ehdr is 64 bytes; Elf64_Phdr.p_align is at offset 48 within
    # the phdr → file offset 112. Written after cp, before strip.
    substituteInPlace src/GNUmakefile --replace \
      '$$(Q)cp $$< $$@' \
      '$$(Q)cp $$< $$@ && printf '"'"'\x00\x00\x01\x00\x00\x00\x00\x00'"'"' | dd of=$$@ bs=1 seek=112 count=8 conv=notrunc 2>/dev/null'
    # readelf is needed to generate loader-info.c (pokedata workaround offset).
    # The Makefile calls bare 'readelf' but only the cross-prefixed version exists.
    substituteInPlace src/GNUmakefile --replace "readelf -s" "${stdenv.cc.targetPrefix}readelf -s"
    # AArch64 requires 16-byte-aligned SP. proot's transfer_load_script sets
    # SP = stack_pointer − buffer_size, which may not be aligned. LLVM 21's
    # loader uses SP-relative addressing in _start, so misalignment → SIGBUS.
    # Fix: align SP down independently; keep x0 pointing to actual data.
    patch -p1 < ${./align-sp.patch}
  '';
  buildInputs = [ talloc ];
  patches = [ ./detranslate-empty.patch ];
  hardeningDisable = [ "zerocallusedregs" ];
  makeFlags = [ "-Csrc" "V=1" ];
  CFLAGS = [ "-O3" "-I../fake-ashmem" ] ++
    (if static then [ "-static" ] else [ ]);
  LDFLAGS = if static then [ "-static" ] else [ ];
  preInstall = "${stdenv.cc.targetPrefix}strip src/proot";
  installPhase = "install -D -m 0755 src/proot $out/bin/${outputBinaryName}";
}
