# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ config, writeScript }:

writeScript "login" ''
  #!/system/bin/sh
  set -e

  export USER="${config.user.userName}"
  export PROOT_TMP_DIR=${config.build.installationDir}/tmp
  export PROOT_L2S_DIR=${config.build.installationDir}/.l2s

  exec "${config.build.installationDir}/bin/proot-static" \
    -b ${config.build.installationDir}/nix:/nix \
    -b ${config.build.installationDir}/bin:/bin \
    -b ${config.build.installationDir}/etc:/etc \
    -b ${config.build.installationDir}/tmp:/tmp \
    -b ${config.build.installationDir}/usr:/usr \
    -b /:/android \
    --link2symlink \
    ${config.build.installationDir}/bin/sh ${config.build.installationDir}/usr/lib/login-inner "$@"
''
