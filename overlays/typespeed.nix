# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

self: super:

let
  nixpkgs = import ./lib/nixpkgs.nix { inherit super; };
in

{
  typespeed = nixpkgs.typespeed.overrideAttrs (old: {
    patches = nixpkgs.typespeed.patches ++ [
        ./typespeed-no-drop-priv.patch
    ];
  });
}
