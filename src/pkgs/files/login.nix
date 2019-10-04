# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ instDir, writeScriptBin }:

writeScriptBin "login" ''
  #!/system/bin/sh
  set -e

  export USER=nix-on-droid
  export PROOT_TMP_DIR=${instDir}/tmp
  export PROOT_L2S_DIR=${instDir}/.l2s

  if [ ! -e ${instDir}/etc/passwd ]; then
    [ -n "$@" ] || echo "Creating /etc/passwd..."
    echo "root:x:0:0:System administrator:${instDir}/root:/bin/sh" > ${instDir}/etc/passwd
    echo "$USER:x:$(/system/bin/stat -c '%u:%g' ${instDir}):$USER:/data/data/com.termux.nix/files/home:/bin/sh" >> ${instDir}/etc/passwd
  fi

  if [ ! -e ${instDir}/etc/group ]; then
    [ -n "$@" ] || echo "Creating /etc/group..."
    echo "root:x:0:" > ${instDir}/etc/group
    echo "$USER:x:$(/system/bin/stat -c '%g' ${instDir}):$USER" >> ${instDir}/etc/group
  fi

  exec ${instDir}/bin/proot \
    -b ${instDir}/nix:/nix \
    -b ${instDir}/bin:/bin \
    -b ${instDir}/etc:/etc \
    -b ${instDir}/tmp:/tmp \
    -b ${instDir}/usr:/usr \
    -b /:/android \
    --link2symlink \
    ${instDir}/bin/sh ${instDir}/bin/login-inner $USER "$@"
''
