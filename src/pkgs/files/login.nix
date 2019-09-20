{ instDir, writeScript }:

writeScript "login" ''
  #!/system/bin/sh
  set -e

  export USER=$(/system/bin/whoami)
  export PROOT_TMP_DIR=${instDir}/tmp
  export PROOT_L2S_DIR=${instDir}/.l2s

  if [ ! -e ${instDir}/etc/passwd ]; then
    [ -n "$@" ] || echo "Creating /etc/passwd..."
    echo "root:x:0:0:System administrator:${instDir}/root:/bin/sh" > ${instDir}/etc/passwd
    echo "nix-on-droid:x:$(/system/bin/stat -c '%u:%g' ${instDir}):nix-on-droid:/data/data/com.termux.nix/files/home:/bin/sh" >> ${instDir}/etc/passwd
  fi

  exec ${instDir}/bin/proot \
    -b ${instDir}/nix:/nix \
    -b ${instDir}/bin:/bin \
    -b ${instDir}/etc:/etc \
    -b ${instDir}/tmp:/tmp \
    -b ${instDir}/usr:/usr \
    -b /:/android \
    --link2symlink \
    ${instDir}/bin/sh ${instDir}/bin/.login-inner $USER "$@"
''
