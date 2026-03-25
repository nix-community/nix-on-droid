# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ runCommand, nixDirectory, prootTermux, bash, pkgs, config, initialPackageInfo }:

runCommand "bootstrap" { } ''
  mkdir --parents $out/{.l2s,bin,dev/shm,etc,root,tmp,usr/{bin,lib}}
  mkdir --parents $out/nix/var/nix/{profiles,gcroots}/per-user/nix-on-droid

  cp --recursive ${nixDirectory}/store $out/nix/store
  cp --recursive ${nixDirectory}/var $out/nix/var
  chmod --recursive u+w $out/nix

  ln --symbolic ${initialPackageInfo.sh} $out/bin/sh

  # Create busybox applet symlinks for common tools needed during initial setup
  BUSYBOX_DIR=$(dirname $(dirname ${initialPackageInfo.sh}))
  for applet in sed grep cat mkdir mv cp rm ln basename dirname env head tail wc tr sort uniq find xargs; do
    ln --symbolic $BUSYBOX_DIR/bin/busybox $out/bin/$applet 2>/dev/null || true
  done
  ln --symbolic $BUSYBOX_DIR/bin/busybox $out/usr/bin/env 2>/dev/null || true

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
