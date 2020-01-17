# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

self: super:

let
  nixpkgs = import ./lib/nixpkgs.nix { inherit super; };
in

{
  htop = nixpkgs.htop.overrideAttrs (old: {
    patches = [
      (super.fetchpatch {
        url = "https://raw.githubusercontent.com/termux/termux-packages/04aea16b13a246c478d28b8cc8c552a052f225ea/packages/htop/fix-missing-macros.patch";
        sha256 = "1cljkjagp66xxcjb6y1m9k4v994slfkd0s6fijh02l3rp8ycvjnv";
      })
    ];
  });
}
