# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ instDir, writeScriptBin }:

writeScriptBin "login" ''
  #!/system/bin/sh
  set -e

  export USER=nix-on-droid
  export PROOT_TMP_DIR=${instDir}/tmp
  export PROOT_L2S_DIR=${instDir}/.l2s

  exec ${instDir}/bin/proot \
    -b ${instDir}/nix:/nix \
    -b ${instDir}/bin:/bin \
    -b ${instDir}/etc:/etc \
    -b ${instDir}/tmp:/tmp \
    -b ${instDir}/usr:/usr \
    -b /:/android \
    --link2symlink \
    ${instDir}/bin/sh ${instDir}/usr/lib/login-inner "$@"
''
