# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ arch, buildPkgs, qemuAarch64Static }:

let
  buildRootDirectory = "root-directory";
  filename = "nix-2.2.2-${arch}-linux.tar.bz2.sha256";

  sha256 = buildPkgs.stdenv.mkDerivation {
    name = "nix-installer-sha256";

    src = builtins.fetchurl "https://nixos.org/releases/nix/nix-2.2.2/${filename}";

    unpackPhase = "true";

    installPhase = ''
      sed -e 's/\(.*\)/"\1"/' $src > $out
    '';
  };

  prootCommand = buildPkgs.lib.concatStringsSep " " [
    "${buildPkgs.proot}/bin/proot"
    (
      if arch == "aarch64"
      then "-q ${qemuAarch64Static}/bin/qemu-aarch64-static"
      else "-b /dev"
    )
    "-r ${buildRootDirectory}"
    "-w /"
  ];
in

buildPkgs.stdenv.mkDerivation {
  name = "nixDirectory";

  src = builtins.fetchurl {
    url = "https://nixos.org/releases/nix/nix-2.2.2/nix-2.2.2-${arch}-linux.tar.bz2";
    sha256 = import sha256;
  };

  PROOT_NO_SECCOMP = 1;  # see https://github.com/proot-me/PRoot/issues/106

  buildPhase = ''
    mkdir --parents ${buildRootDirectory}/nix
    cp --recursive store ${buildRootDirectory}/nix/store

    CACERT=$(find ${buildRootDirectory}/nix/store -path '*-nss-cacert-*/ca-bundle.crt' | sed 's,^${buildRootDirectory},,')
    PKG_BASH=$(find ${buildRootDirectory}/nix/store -path '*/bin/bash' | sed 's,^${buildRootDirectory},,')
    PKG_BASH=''${PKG_BASH%/bin/bash}
    PKG_COREUTILS=$(find ${buildRootDirectory}/nix/store -path '*/bin/env' | sed 's,^${buildRootDirectory},,')
    PKG_COREUTILS=''${PKG_COREUTILS%/bin/env}
    PKG_NIX=$(find ${buildRootDirectory}/nix/store -path '*/bin/nix' | sed 's,^${buildRootDirectory},,')
    PKG_NIX=''${PKG_NIX%/bin/nix}

    ${prootCommand} "$PKG_NIX/bin/nix-store" --init
    ${prootCommand} "$PKG_NIX/bin/nix-store" --load-db < .reginfo

    cat > package-info.nix <<EOF
    {
      bash = "$PKG_BASH";
      cacert = "$CACERT";
      coreutils = "$PKG_COREUTILS";
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
