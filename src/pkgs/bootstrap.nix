# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ buildPkgs, files, nixDirectory, proot }:

let
  packageInfo = import "${nixDirectory}/nix-support/package-info.nix";
in

buildPkgs.runCommand "bootstrap" { } ''
  mkdir --parents $out/{.l2s,bin,etc/nix,nix,root,tmp,usr/bin}

  cp --recursive ${nixDirectory}/store $out/nix/store
  cp --recursive ${nixDirectory}/var $out/nix/var
  chmod --recursive u+w $out/nix

  ln --symbolic --no-dereference ${packageInfo.bash}/bin/sh $out/bin/sh
  ln --symbolic --no-dereference ${packageInfo.coreutils}/bin/env $out/usr/bin/env

  install -D -m 0755 ${proot}/bin/proot $out/bin/proot

  cp ${files.login}/bin/login $out/bin/login
  cp ${files.login-inner}/usr/lib/login-inner $out/usr/lib/login-inner

  cp ${files.home-nix-default}/etc/home.nix.default $out/etc/home.nix.default
  cp ${files.nix-conf}/etc/nix/nix.conf $out/etc/nix/nix.conf
  cp ${files.resolv-conf}/etc/resolv.conf $out/etc/resolv.conf

  find $out -executable -type f | sed s@^$out/@@ > $out/EXECUTABLES.txt

  find $out -type l | while read -r LINK; do
    LNK=''${LINK#$out/}
    TGT=$(readlink "$LINK")
    echo "$TGT←$LNK" >> $out/SYMLINKS.txt
    rm "$LINK"
  done
''
