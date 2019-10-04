# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ buildPkgs, nixDirectory }:

let
  inherit (buildPkgs) writeScript writeText;

  instDir = "/data/data/com.termux.nix/files/usr";

  packageInfo = import "${nixDirectory}/nix-support/package-info.nix";

  callPackage = buildPkgs.lib.callPackageWith {
    inherit instDir nixDirectory packageInfo writeScript writeText;
  };
in

{
  homeNixDefault = writeText "home.nix.default" (builtins.readFile ./raw/home.nix.default);

  login = callPackage ./login.nix { };

  loginInner = callPackage ./login-inner.nix { };

  nixConf = writeText "nix.conf" ''
    sandbox = false
    substituters = https://cache.nixos.org https://nix-on-droid.cachix.org
    trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-on-droid.cachix.org-1:56snoMJTXmDRC1Ei24CmKoUqvHJ9XCp+nidK7qkMQrU=
  '';

  resolvConf = writeText "resolv.conf" ''
    nameserver 1.1.1.1
    nameserver 8.8.8.8
  '';
}
