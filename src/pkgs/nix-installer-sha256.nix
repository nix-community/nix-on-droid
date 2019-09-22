# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ arch, buildPkgs }:

buildPkgs.stdenv.mkDerivation {
  name = "nix-installer-sha256";

  src = builtins.fetchurl "https://nixos.org/releases/nix/nix-2.2.2/nix-2.2.2-${arch}-linux.tar.bz2.sha256";

  unpackPhase = "true";

  installPhase = ''
    sed -e 's/\(.*\)/"\1"/' $src > $out
  '';
}
