{ buildPkgs, nixDirectory }:

let
  inherit (buildPkgs) writeScript writeText;

  instDir = "/data/data/com.termux.nix/files/usr";

  packageInfo = import "${nixDirectory}/nix-support/package-info.nix";

  callPackage = buildPkgs.lib.callPackageWith {
    inherit instDir nixDirectory packageInfo writeScript writeText;
  };
in

{
  homeNixDefault = callPackage ./home-nix-default.nix { };

  login = callPackage ./login.nix { };

  loginInner = callPackage ./login-inner.nix { };

  nixConf = writeText "nix.conf" ''
    sandbox = false
  '';

  nixOnDroidInstall = callPackage ./nix-on-droid-install.nix { };

  resolvConf = writeText "resolv.conf" ''
    nameserver 1.1.1.1
    nameserver 8.8.8.8
  '';
}
