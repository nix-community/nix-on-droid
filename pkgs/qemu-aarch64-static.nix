# Copyright (c) 2019-2021, see AUTHORS. Licensed under MIT License, see LICENSE.

{ stdenv }:

stdenv.mkDerivation {
  name = "qemu-aarch64-static";

  src = builtins.fetchurl {
    url = "https://github.com/multiarch/qemu-user-static/releases/download/v5.2.0-2/qemu-aarch64-static";
    sha256 = "0v1c8nchf5s7db11spixp2gsp94018ig7nz2ha1f4bngr0bgbk92";
  };

  dontUnpack = true;
  installPhase = "install -D -m 0755 $src $out/bin/qemu-aarch64-static";
}
