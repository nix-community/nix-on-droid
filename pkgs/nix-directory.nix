# Copyright (c) 2019-2025, see AUTHORS. Licensed under MIT License, see LICENSE.

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

  # https://github.com/NixOS/nixpkgs/pull/471845
  staticNix = pkgsStatic.nix.overrideScope (_: _: {
    libblake3 = pkgsStatic.libblake3.override { useTBB = false; };
  });
  # nix-cli is not exposed externally, hacking around it
  staticNixCli = "$(dirname $(dirname $(readlink ${staticNix}/bin/nix)))";

  prootCommand = lib.concatStringsSep " " [
    "${proot}/bin/proot"
    "-b ${staticNixCli}:/static-nix"
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
    url = "https://nixos.org/releases/nix/nix-2.31.2/nix-2.31.2-${system}.tar.xz";
    sha256 =
      let
        nixShas = {
          aarch64-linux = "sha256:0mh4aqzx4dzf1m80al2ffx5p2axcwn2qzxzq9f5p2v892a255nv4";
          x86_64-linux = "sha256:0q4azlxwqvzrad4bgbwggvm7lc4waawvy25sci4225nhxs37rxni";
        };
      in
      nixShas.${system};
  };

  PROOT_NO_SECCOMP = 1; # see https://github.com/proot-me/PRoot/issues/106

  buildPhase = ''
    # create nix state directory to satisfy nix heuristics to recognize the manual create /nix directory as valid nix store
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
  '';

  installPhase = ''
    mkdir $out
    cp --recursive ${buildRootDirectory}/nix/store $out/store
    cp --recursive ${buildRootDirectory}/nix/var $out/var
    install -D -m 0644 package-info.nix $out/nix-support/package-info.nix
  '';

  fixupPhase = "true";
}
