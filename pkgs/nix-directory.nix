# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config
, lib
, stdenvNoCC
, closureInfo
, prootTermux
, proot
, pkgsStatic
, system
}:

let
  buildRootDirectory = "root-directory";

  prootCommand = lib.concatStringsSep " " [
    "${proot}/bin/proot"
    "-b /proc:/proc" # needed because tries to access /proc/self/exe
    "-r ${buildRootDirectory}"
    "-w /"
  ];

  prootTermuxClosure = closureInfo {
    rootPaths = [
      prootTermux
    ];
  };
in

stdenvNoCC.mkDerivation {
  name = "nix-directory";

  src = builtins.fetchurl {
    url = "https://nixos.org/releases/nix/nix-2.34.3/nix-2.34.3-${system}.tar.xz";
    sha256 =
      let
        nixShas = {
          aarch64-linux = "sha256:0c2fkqnbqq9dspw0gil3ixdd5qqwzm763hqrxagpawxnjrv4wdi1";
          x86_64-linux = "sha256:1l7za5hi1sd5b266pxfrk2yi3212rfgdlv46kqa6w0kdb0xwm23q";
        };
      in
      nixShas.${system};
  };

  PROOT_NO_SECCOMP = 1; # see https://github.com/proot-me/PRoot/issues/106

  buildPhase = ''
    # create nix state directory to satisfy nix heuristics to recognize the manual create /nix directory as valid nix store
    mkdir --parents ${buildRootDirectory}/nix/var/nix/db
    cp --recursive store ${buildRootDirectory}/nix/store

    CACERT=$(find ${buildRootDirectory}/nix/store -path '*-nss-cacert-*/ca-bundle.crt' | head -1 | sed 's,^${buildRootDirectory},,')
    PKG_SH=$(find ${buildRootDirectory}/nix/store -path '*/bin/sh' | head -1 | sed 's,^${buildRootDirectory},,')
    PKG_NIX=$(find ${buildRootDirectory}/nix/store -path '*/bin/nix' | head -1 | sed 's,^${buildRootDirectory},,')
    PKG_NIX=''${PKG_NIX%/bin/nix}

    for i in $(< ${prootTermuxClosure}/store-paths); do
      cp --archive "$i" "${buildRootDirectory}$i"
    done

    # Copy static nix into root directory so proot can access it
    # Must dereference symlinks since the binary symlinks point to absolute /nix/store paths
    mkdir -p ${buildRootDirectory}/static-nix/bin
    cp -L ${pkgsStatic.nix}/bin/nix ${buildRootDirectory}/static-nix/bin/nix
    ln -s nix ${buildRootDirectory}/static-nix/bin/nix-store

    USER=${config.user.userName} ${prootCommand} "/static-nix/bin/nix-store" --init
    USER=${config.user.userName} ${prootCommand} "/static-nix/bin/nix-store" --load-db < .reginfo
    USER=${config.user.userName} ${prootCommand} "/static-nix/bin/nix-store" --load-db < ${prootTermuxClosure}/registration

    cat > package-info.nix <<EOF
    {
      sh = "$PKG_SH";
      cacert = "$CACERT";
      nix = "$PKG_NIX";
    }
    EOF
  '';

  installPhase = ''
    mkdir $out
    cp --recursive ${buildRootDirectory}/nix/store $out/store
    cp --recursive ${buildRootDirectory}/nix/var $out/var
    install -D -m 0644 package-info.nix $out/nix-support/package-info.nix
  '';

  fixupPhase = "true";
}
