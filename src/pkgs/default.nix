{ arch, buildPkgs, crossPkgs, crossStaticPkgs } @ args:

let
  callPackage = buildPkgs.lib.callPackageWith (args // pkgs);

  pkgs = rec {
    bootstrap = callPackage ./bootstrap.nix { };

    bootstrapZip = callPackage ./bootstrap-zip.nix { };

    files = callPackage ./files { };

    nixDirectory = callPackage ./nix-directory.nix { };

    proot = callPackage ./proot.nix { };

    qemuAarch64Static = callPackage ./qemu-aarch64-static.nix { };

    talloc = callPackage ./talloc.nix { };
  };
in

pkgs
