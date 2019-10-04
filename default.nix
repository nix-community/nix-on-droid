# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

let
  nixpkgs = import <nixpkgs> { };

  pkgs = import ./src {
    arch = if nixpkgs.stdenv.hostPlatform.isArm then "aarch64" else "i686";
    initialBuild = false;
  };
in

{
  inherit (pkgs) proot;

  basic-environment = nixpkgs.buildEnv {
    name = "basic-environment";

    paths = [
      nixpkgs.bashInteractive
      nixpkgs.cacert
      nixpkgs.coreutils
      nixpkgs.nix
      # pkgs.proot
      pkgs.files.hmInstall
      pkgs.files.homeNixDefault
      pkgs.files.login
      pkgs.files.loginInner
      pkgs.files.nixConf
      pkgs.files.nixOnDroidLinker
      pkgs.files.resolvConf
    ];
  };
} // pkgs.files
