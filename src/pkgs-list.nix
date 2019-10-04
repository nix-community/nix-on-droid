# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ fetchFromGitHub, arch }:

let
  # head of nixos-19.03 as of 2019-09-15
  pinnedPkgsSrc = fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "2dfae8e22fde5032419c3027964c406508332974";
    sha256 = "0293j9wib78n5nspywrmd9qkvcqq2vcrclrryxqnaxvj3bs1c0vj";
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
