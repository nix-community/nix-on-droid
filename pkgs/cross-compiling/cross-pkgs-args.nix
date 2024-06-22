# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ lib, config, system, targetSystem }:

let
  arch = lib.strings.removeSuffix "-linux" targetSystem;
in
{
  inherit system;

  crossSystem = {
    config = "${arch}-unknown-linux-android";
    sdkVer = "32";
    libc = "bionic";
    useAndroidPrebuilt = false;
    useLLVM = true;
    isStatic = true;
  };
}
