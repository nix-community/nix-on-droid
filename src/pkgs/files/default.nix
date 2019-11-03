# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ callPackage, writeTextDir }:

{
  etc-group = callPackage ./etc-group.nix { };

  etc-passwd = callPackage ./etc-passwd.nix { };

  hm-install = callPackage ./hm-install.nix { };

  home-nix-default = writeTextDir "etc/home.nix.default" (builtins.readFile ./raw/home.nix.default);

  login = callPackage ./login.nix { };

  login-inner = callPackage ./login-inner.nix { };

  nix-conf = writeTextDir "etc/nix/nix.conf" ''
    sandbox = false
    substituters = https://cache.nixos.org https://nix-on-droid.cachix.org
    trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-on-droid.cachix.org-1:56snoMJTXmDRC1Ei24CmKoUqvHJ9XCp+nidK7qkMQrU=
  '';

  nix-on-droid-linker = callPackage ./nix-on-droid-linker.nix { };

  resolv-conf = writeTextDir "etc/resolv.conf" ''
    nameserver 1.1.1.1
    nameserver 8.8.8.8
  '';
}
