# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ config, lib, libjpeg, path }:

let
  overlayJpegNoStatic = self: super: {
    inherit libjpeg;
  };

  crossSystem = {
    config = "${config.core.arch}-unknown-linux-android";
    sdkVer = "24";
    ndkVer = "18b";
    useAndroidPrebuilt = true;
  };
in

{
  cross = lib.loadNixpkgs { inherit crossSystem; };

  crossStatic = lib.loadNixpkgs {
    inherit crossSystem;

    crossOverlays = [
      (import "${path}/pkgs/top-level/static.nix")
      overlayJpegNoStatic
    ];
  };
}
