# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

self: super:

let
  nixpkgs = import ./lib/nixpkgs.nix { inherit super; };
in

{
  htop = nixpkgs.stdenv.mkDerivation rec {
    pname = "htop";
    version = "2.2.0";

    src = nixpkgs.fetchurl {
      url = "https://hisham.hm/htop/releases/${version}/${pname}-${version}.tar.gz";
      sha256 = "0mrwpb3cpn3ai7ar33m31yklj64c3pp576vh1naqff6f21pq5mnr";
    };

    nativeBuildInputs = [ nixpkgs.python3 ];
    buildInputs = [ nixpkgs.ncurses ];

    prePatch = ''
      patchShebangs scripts/MakeHeader.py
    '';

    meta = with nixpkgs.stdenv.lib; {
      description = "An interactive process viewer for Linux";
      homepage = "https://hisham.hm/htop/";
      license = licenses.gpl2Plus;
    };

    patches = [
      (nixpkgs.fetchpatch {
        url = "https://raw.githubusercontent.com/termux/termux-packages/04aea16b13a246c478d28b8cc8c552a052f225ea/packages/htop/fix-missing-macros.patch";
        sha256 = "1cljkjagp66xxcjb6y1m9k4v994slfkd0s6fijh02l3rp8ycvjnv";
      })
    ];
  };
}
