# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ pkgs
, crossPkgs
, targetPkgs
, nixOnDroidChannelURL ? null
, nixpkgsChannelURL ? null
, nixOnDroidFlakeURL ? null
}:

let
  targetSystem = crossPkgs.stdenv.hostPlatform.system;

  # Use prebuilt bootstrap packages from nixpkgs cache
  closureInfo = pkgs.closureInfo {
    rootPaths = with targetPkgs; [ bash cacert nix ];
  };
  initialPackageInfo = {
    inherit (targetPkgs) bash nix;
    cacert = "${targetPkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
  };

  urlOptionValue = url: envVar:
    let
      envValue = builtins.getEnv envVar;
    in
    pkgs.lib.mkIf
      (envValue != "" || url != null)
      (if url == null then envValue else url);

  modules = import ../modules {
    inherit pkgs crossPkgs targetSystem;

    isFlake = true;

    config = {
      imports = [ ../modules/build/initial-build.nix ];

      _module.args = {
        inherit initialPackageInfo;
        pkgs = pkgs.lib.mkForce pkgs; # to override ./modules/nixpkgs/config.nix
      };

      system.stateVersion = "24.05";

      # Fix invoking bash after initial build.
      user.shell = "${initialPackageInfo.bash}/bin/bash";

      build = {
        channel = {
          nixpkgs = urlOptionValue nixpkgsChannelURL "NIXPKGS_CHANNEL_URL";
          nix-on-droid = urlOptionValue nixOnDroidChannelURL "NIX_ON_DROID_CHANNEL_URL";
        };

        flake.nix-on-droid = urlOptionValue nixOnDroidFlakeURL "NIX_ON_DROID_FLAKE_URL";
      };
    };
  };

  callPackage = pkgs.lib.callPackageWith (
    pkgs // customPkgs // {
      inherit (modules) config;
      inherit callPackage closureInfo initialPackageInfo targetSystem;
    }
  );

  staticPkgs = crossPkgs.pkgsStatic.pkgsLLVM;

  customPkgs = rec {
    bootstrap = callPackage ./bootstrap.nix { };
    bootstrapZip = callPackage ./bootstrap-zip.nix { };
    prootTermux = staticPkgs.callPackage ./proot-termux { talloc = tallocStatic; };
    tallocStatic = staticPkgs.callPackage ./talloc { };
  };
in

{
  inherit (modules) config;
  inherit customPkgs;
}
