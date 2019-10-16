# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ fetchFromGitHub, arch }:

let
  # head of nixos-19.09 as of 2019-10-14
  pinnedPkgsSrc = fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "45a25ff41a2309099ff2e70b2f37debd5e567618";
    sha256 = "0w37p98i47d7snhckz8a3a60v0f05b5047vsm4rczink9mk9x7r3";
  };

  defaultNixpkgsArgs = {
    config = { };
    overlays = [ ];
  };

  pinnedPkgs = import pinnedPkgsSrc defaultNixpkgsArgs;

  overlayJpegNoStatic = self: super: {
    inherit (pinnedPkgs) libjpeg;
  };

  crossSystem = {
    config = "${arch}-unknown-linux-android";
    sdkVer = "24";
    ndkVer = "18b";
    useAndroidPrebuilt = true;
  };
in

{
  inherit pinnedPkgs;

  crossPkgs = import pinnedPkgsSrc ({ inherit crossSystem; } // defaultNixpkgsArgs);

  crossStaticPkgs = import pinnedPkgsSrc ({
    inherit crossSystem;

    crossOverlays = [
      (import "${pinnedPkgsSrc}/pkgs/top-level/static.nix")
      overlayJpegNoStatic
    ];
  } // defaultNixpkgsArgs);
}
