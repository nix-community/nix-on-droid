# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, libjpeg, path }:

let
  loadNixpkgs = import ../lib/load-nixpkgs.nix;

  overlayJpegNoStatic = self: super: {
    inherit libjpeg;
  };

  crossSystem = {
    config = "${config.build.arch}-unknown-linux-android";
    sdkVer = "24";
    ndkVer = "18b";
    useAndroidPrebuilt = true;
  };
in

{
  cross = loadNixpkgs { inherit crossSystem; };

  crossStatic = loadNixpkgs {
    inherit crossSystem;

    crossOverlays = [
      (import "${path}/pkgs/top-level/static.nix")
      overlayJpegNoStatic
    ];
  };
}
