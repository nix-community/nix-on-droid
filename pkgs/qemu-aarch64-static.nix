# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

{ stdenv }:

stdenv.mkDerivation {
  name = "qemu-aarch64-static";

  src = builtins.fetchurl {
    url = "https://github.com/multiarch/qemu-user-static/releases/download/v5.1.0-7/qemu-aarch64-static";
    sha256 = "0yzlrlknslvas58msrbbq3hazphyydrbaqrd840bd1c7vc9lcrh6";
  };

  dontUnpack = true;
  installPhase = "install -D -m 0755 $src $out/bin/qemu-aarch64-static";
}
