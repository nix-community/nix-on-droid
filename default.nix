# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

{ pkgs ? import <nixpkgs> { } }:

rec {
  nix-on-droid = pkgs.callPackage ./nix-on-droid { };
}
