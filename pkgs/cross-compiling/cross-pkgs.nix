# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config }:

let
  loadNixpkgs = import ../lib/load-nixpkgs.nix;

  crossSystem = {
    config = "${config.build.arch}-unknown-linux-android";
    sdkVer = "32";
    libc = "bionic";
    useAndroidPrebuilt = false;
    useLLVM = true;
    isStatic = true;
  };

in

loadNixpkgs { inherit crossSystem; }
