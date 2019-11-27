# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ config, lib, writeScript }:

let
  inherit (config.build) installationDir;
in

writeScript "login" ''
  #!/system/bin/sh
  set -e

  export USER="${config.user.userName}"
  export PROOT_TMP_DIR=${installationDir}/tmp
  export PROOT_L2S_DIR=${installationDir}/.l2s

  ${
    if config.build.initialBuild
    then ''
      ${installationDir}/bin/proot-static \
        -b ${installationDir}/nix:/nix \
        -b ${installationDir}/bin:/bin \
        -b ${installationDir}/etc:/etc \
        -b ${installationDir}/tmp:/tmp \
        -b ${installationDir}/usr:/usr \
        -b /:/android \
        --link2symlink \
        ${installationDir}/bin/sh ${installationDir}/usr/lib/login-inner "$@"

      exec ${installationDir}/bin/login "$@"
    ''
    else ''
      if [[ -x ${installationDir}/bin/.proot-static.new ]] && ! $(/system/bin/pgrep proot-static); then
        /system/bin/mv ${installationDir}/bin/.proot-static.new ${installationDir}/bin/proot-static
      fi

      exec ${installationDir}/bin/proot-static \
        -b ${installationDir}/nix:/nix \
        -b ${installationDir}/bin:/bin \
        -b ${installationDir}/etc:/etc \
        -b ${installationDir}/tmp:/tmp \
        -b ${installationDir}/usr:/usr \
        -b /:/android \
        --link2symlink \
        ${installationDir}/bin/sh ${installationDir}/usr/lib/login-inner "$@"
    ''
  }
''
