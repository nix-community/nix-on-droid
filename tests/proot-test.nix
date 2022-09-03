# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

{ pkgs ? (import ../pkgs/lib/load-nixpkgs.nix { }) }:

pkgs.callPackage ../pkgs/proot-termux {
  stdenv = pkgs.stdenv;
  static = false;
  outputBinaryName = "proot";
}
