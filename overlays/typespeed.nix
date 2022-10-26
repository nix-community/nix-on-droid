# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

_self: super:

let
  nixpkgs = import ./lib/nixpkgs.nix { inherit super; };
in

{
  typespeed = nixpkgs.typespeed.overrideAttrs (_old: {
    patches = nixpkgs.typespeed.patches ++ [
      ./typespeed-no-drop-priv.patch
    ];
  });
}
