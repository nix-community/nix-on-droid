# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ }:

let
  nixpkgs = import <nixpkgs> { };

  pkgs = import ./src {
    arch = if nixpkgs.stdenv.hostPlatform.isArm then "aarch64" else "i686";
    initialBuild = false;
  };
in

{
  inherit (pkgs) proot-termux;

  basic-environment = nixpkgs.buildEnv {
    name = "basic-environment";

    paths = [
      nixpkgs.bashInteractive
      nixpkgs.cacert
      nixpkgs.coreutils
      nixpkgs.nix
      # pkgs.proot-termux
      pkgs.files.etc-group
      pkgs.files.etc-passwd
      pkgs.files.hm-install
      pkgs.files.home-nix-default
      pkgs.files.login
      pkgs.files.login-inner
      pkgs.files.nix-conf
      pkgs.files.nix-on-droid-linker
      pkgs.files.resolv-conf
    ];
  };
} // pkgs.files
