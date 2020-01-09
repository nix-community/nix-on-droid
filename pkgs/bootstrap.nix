# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

{ runCommand, nixDirectory, prootTermux, bash, pkgs, config }:

let
  packageInfo = import "${nixDirectory}/nix-support/package-info.nix";
in

runCommand "bootstrap" { } ''
  mkdir --parents $out/{.l2s,bin,etc,nix,root,tmp,usr/{bin,lib}}

  cp --recursive ${nixDirectory}/store $out/nix/store
  cp --recursive ${nixDirectory}/var $out/nix/var
  chmod --recursive u+w $out/nix

  ln --symbolic ${packageInfo.bash}/bin/sh $out/bin/sh
  ln --symbolic ${packageInfo.coreutils}/bin/env $out/usr/bin/env

  install -D -m 0755 ${prootTermux}/bin/proot-static $out/bin/proot-static

  cp ${config.environment.files.login} $out/bin/login
  cp ${config.environment.files.loginInner} $out/usr/lib/login-inner

  ${bash}/bin/bash ${../modules/environment/etc/setup-etc.sh} $out/etc ${config.build.activationPackage}/etc

  cp --dereference --recursive $out/etc/static $out/etc/.static.tmp
  rm $out/etc/static
  mv $out/etc/.static.tmp $out/etc/static

  find $out -executable -type f | sed s@^$out/@@ > $out/EXECUTABLES.txt

  find $out -type l | while read -r LINK; do
    LNK=''${LINK#$out/}
    TGT=$(readlink "$LINK")
    echo "$TGT←$LNK" >> $out/SYMLINKS.txt
    rm "$LINK"
  done
''
