# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config
, lib
, stdenvNoCC
, fetchurl
, closureInfo
, prootTermux
, proot
, lixStatic
, system
,
}:

let
  buildRootDirectory = "root-directory";

  prootCommand = lib.concatStringsSep " " [
    "${proot}/bin/proot"
    "-b ${lixStatic}:/static-nix"
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

stdenvNoCC.mkDerivation
  (finalAttrs: {
    pname = "nix-directory";
    version = "2.32.4";

    src = fetchurl {
      url = "https://releases.nixos.org/nix/nix-${finalAttrs.version}/nix-${finalAttrs.version}-${system}.tar.xz";
      hash = {
        aarch64-linux = "sha256-7oVBxZWigweaUsoUsdt/iPLZJ9b0a2G87eWr+xBOW1c=";
        x86_64-linux = "sha256-Bzd1XzEG6N/78mp3rzmIiOhCGXS5H+K4YFLIkfceFrU=";
      }.${system};
    };

    env.PROOT_NO_SECCOMP = 1; # see https://github.com/proot-me/PRoot/issues/106

    buildPhase = ''
      runHook preBuild
    ''
    # create nix state directory to satisfy nix heuristics to recognize the manual create /nix directory as valid nix store
    + ''
      mkdir --parents ${buildRootDirectory}/nix/var/nix/db
      cp --recursive store ${buildRootDirectory}/nix/store

      CACERT=$(find ${buildRootDirectory}/nix/store -path '*-nss-cacert-*/ca-bundle.crt' | sed 's,^${buildRootDirectory},,')
      PKG_BASH=$(find ${buildRootDirectory}/nix/store -path '*/bin/bash' | sed 's,^${buildRootDirectory},,')
      PKG_BASH=''${PKG_BASH%/bin/bash}
      PKG_NIX=$(find ${buildRootDirectory}/nix/store -path '*/bin/nix' | sed 's,^${buildRootDirectory},,')
      PKG_NIX=''${PKG_NIX%/bin/nix}

      for i in $(< ${prootTermuxClosure}/store-paths); do
        cp --archive "$i" "${buildRootDirectory}$i"
      done

      USER=${config.user.userName} ${prootCommand} "/static-nix/bin/nix-store" --init
      USER=${config.user.userName} ${prootCommand} "/static-nix/bin/nix-store" --load-db < .reginfo
      USER=${config.user.userName} ${prootCommand} "/static-nix/bin/nix-store" --load-db < ${prootTermuxClosure}/registration

      cat > package-info.nix <<EOF
      {
        bash = "$PKG_BASH";
        cacert = "$CACERT";
        nix = "$PKG_NIX";
      }
      EOF

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir $out
      cp --recursive ${buildRootDirectory}/nix/store $out/store
      cp --recursive ${buildRootDirectory}/nix/var $out/var
      install -D --mode=0644 package-info.nix $out/nix-support/package-info.nix

      runHook postInstall
    '';

    dontPatchELF = true;

    dontStrip = true;

    preFixup = ''
      find $out -xtype l -print -delete
    '';
  })
