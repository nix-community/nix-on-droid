{ fetchFromGitHub, arch }:

let
  pinnedPkgs = fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "2dfae8e22fde5032419c3027964c406508332974";
    sha256 = "0293j9wib78n5nspywrmd9qkvcqq2vcrclrryxqnaxvj3bs1c0vj";
  };

  buildPkgs = import pinnedPkgs { };

  overlayJpegNoStatic = self: super: {
    inherit (buildPkgs) libjpeg;
  };

  crossSystem = {
    config = "${arch}-unknown-linux-android";
    sdkVer = "24";
    ndkVer = "18b";
    useAndroidPrebuilt = true;
  };
in

{
  inherit buildPkgs;

  crossPkgs = import pinnedPkgs { inherit crossSystem; };

  crossStaticPkgs = import pinnedPkgs {
    inherit crossSystem;

    crossOverlays = [
      (import "${pinnedPkgs}/pkgs/top-level/static.nix")
      overlayJpegNoStatic
    ];
  };
}
