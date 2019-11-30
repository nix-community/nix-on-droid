# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ arch, nixOnDroidChannelURL ? null, nixpkgsChannelURL ? null }:

let
  loadNixpkgs = import lib/load-nixpkgs.nix;

  nixpkgs = loadNixpkgs { };

  modules = import ../modules {
    pkgs = nixpkgs;
    initialBuild = true;

    config = {
      imports = [ ../modules/build/initial-build.nix ];

      _module.args = { inherit customPkgs; };

      build = {
        inherit arch;

        channel = with nixpkgs.lib; {
          nixpkgs = mkIf (nixpkgsChannelURL != null) nixpkgsChannelURL;
          nix-on-droid = mkIf (nixOnDroidChannelURL != null) nixOnDroidChannelURL;
        };
      };
    };
  };

  callPackage = nixpkgs.lib.callPackageWith (
    nixpkgs // customPkgs // {
      inherit (modules) config;
      inherit callPackage;
    }
  );

  customPkgs = rec {
    bootstrap = callPackage ./bootstrap.nix { };
    bootstrapZip = callPackage ./bootstrap-zip.nix { };
    nixDirectory = callPackage ./nix-directory.nix { };
    packageInfo = import "${nixDirectory}/nix-support/package-info.nix";
    prootTermux = callPackage ./cross-compiling/proot-termux.nix { };
    qemuAarch64Static = callPackage ./qemu-aarch64-static.nix { };
    talloc = callPackage ./cross-compiling/talloc.nix { };
  };
in

customPkgs
