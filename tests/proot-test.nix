# Copyright (c) 2019-2021, see AUTHORS. Licensed under MIT License, see LICENSE.

{ pkgs ? (import ../pkgs/lib/load-nixpkgs.nix {}) }:

let
  stdenv = pkgs.stdenv;
in
  pkgs.callPackage ../pkgs/proot-termux {
    outputBinaryName = "proot";
    inherit pkgs;
  }
