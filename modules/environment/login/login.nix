# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, writeScript }:

let
  inherit (config.build) installationDir extraProotOptions;
in

writeScript "login" ''
  #!/system/bin/sh
  # This file is generated by nix-on-droid. DO NOT EDIT.
  set -eu -o pipefail

  export USER="${config.user.userName}"
  export HOME="${config.user.home}"
  export PROOT_TMP_DIR=${installationDir}/tmp
  export PROOT_L2S_DIR=${installationDir}/.l2s

  if ! /system/bin/pgrep proot-static > /dev/null; then
    if test -e ${installationDir}/bin/.proot-static.new; then
      echo "Installing new proot-static..."
      /system/bin/mv ${installationDir}/bin/.proot-static.new ${installationDir}/bin/proot-static
    fi

    if test -e ${installationDir}/usr/lib/.login-inner.new; then
      echo "Installing new login-inner..."
      /system/bin/mv ${installationDir}/usr/lib/.login-inner.new ${installationDir}/usr/lib/login-inner
    fi
  fi

  exec ${installationDir}/bin/proot-static \
    -b ${installationDir}/nix:/nix \
    -b ${installationDir}/bin:/bin \
    -b ${installationDir}/etc:/etc \
    -b ${installationDir}/tmp:/tmp \
    -b ${installationDir}/usr:/usr \
    -b ${installationDir}/dev/shm:/dev/shm \
    -b /:/android \
    --link2symlink \
    --sysvipc \
    ${builtins.concatStringsSep " " extraProotOptions} \
    ${installationDir}/bin/sh ${installationDir}/usr/lib/login-inner "$@"
''
