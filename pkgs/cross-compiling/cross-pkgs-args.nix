# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, system }:

{
  inherit system;

  crossSystem = {
    config = "${config.build.arch}-unknown-linux-android";
    sdkVer = "32";
    libc = "bionic";
    useAndroidPrebuilt = false;
    useLLVM = true;
    isStatic = true;
  };
}
