# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

{ stdenv }:

stdenv.mkDerivation {
  name = "qemu-aarch64-static";

  src = builtins.fetchurl {
    url = "https://github.com/multiarch/qemu-user-static/releases/download/v5.0.0-2/qemu-aarch64-static";
    sha256 = "0q4hxq7kfxm70wvqybrcr9db8akwlzxf5jljdxv4lff8ivlhr6rw";
  };

  unpackPhase = "true";

  installPhase = ''
    install -D -m 0755 $src $out/bin/qemu-aarch64-static
  '';
}
