# Copyright (c) 2019-2021, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, path }:

let
  loadNixpkgs = import ../lib/load-nixpkgs.nix;

  crossSystem = {
    config = "${config.build.arch}-unknown-linux-android";
    ndkVer = "21";

    # that one is cool because it could make its way on-device one day,
    # but it currently isn't static-friendly:
    #   sdkVer = "30";
    #   libc = "bionic";
    #   useAndroidPrebuilt = false;
    #   useLLVM = true;

    # use that one instead
    sdkVer = "29";
    useAndroidPrebuilt = true;
  };
in

loadNixpkgs { inherit crossSystem; }
