# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ config, writeScriptBin }:

let
  instDir = config.core.installation;
in

writeScriptBin "login" ''
  #!/system/bin/sh
  set -e

  ORIGINAL_PATH="$PATH"
  ANDROID_LIKELY_PATH="/sbin:/system/sbin:/system/bin:/system/xbin"
  ANDROID_LIKELY_PATH="$ANDROID_LIKELY_PATH:/vendor/bin:/vendor/xbin"
  PATH="$ANDROID_LIKELY_PATH:$OLD_PATH"

  resolve_link() {
    #echo "resolving $1" >&2
    if [ -x "$1" ]; then
      #echo "$1 exists, done" >&2
      echo "$1"
    elif [ -L "$1" ]; then
      TGT=$(readlink "$1")
      #echo "$1 is a link pointing to $TGT" >&2
      case $TGT in
        /data/data/com.termux.nix/files/*)  # some parent is a broken link
          #echo "$TGT link looks fine, resolving further" >&2
          resolve_link "$TGT"
        ;;
        /*)  # broken link, just add the prefix
          #echo "$TGT makes sense only inside nix-on-droid, fixing it" >&2
          resolve_link "/data/data/com.termux.nix/files/usr$TGT"
        ;;
        *)  # relative link, replace parent
          TGT="$(dirname "$1")/$TGT"
          #echo "This link is a relative link, resolve it as $TGT" >&2
          resolve_link "$TGT"
        ;;
      esac
    else  # OK, now some parent is a broken link =/
      #echo "=/" >&2
      P=$1
      TAIL=""                          # /something/broken_symlink/smth/else
      while [ ! -e "$P" ]; do          # /something/broken_symlink/smth (iter 2)
        TAIL="$(basename "$P")/$TAIL"  # something/else/                (iter 2)
        P=$(dirname "$P")              # /something/broken_symlink      (iter 2)
        #echo "inspecting $P" >&2
        if [ -L "$P" ] && [ ! -x "$P" ]; then
          TAIL=''${TAIL%%/}  # strip slashes
          #echo "$P is the broken symlink parent, fix that and add $TAIL" >&2
          P="$(resolve_link "$P")"
          #echo "resolved to $P, now adding $TAIL" >&2
          resolve_link "$P/$TAIL"
        break
        #else
          #echo "$P is not a symlink, we need to go deeper" >&2
        fi
      done
    fi
  }

  export USER="${config.user.user}"
  export PROOT_TMP_DIR=${instDir}/tmp
  export PROOT_L2S_DIR=${instDir}/.l2s

  PROOT=${instDir}/bin/proot-static
  if [ ! -x "$PROOT" ]; then
    PROOT=$(resolve_link "$PROOT")
  fi
  if [ ! -x "$PROOT" ]; then
    echo "Could not find proot-static" >&2
    exit 244
  fi

  PATH="$ORIGINAL_PATH"
  exec "$PROOT" \
    -b ${instDir}/nix:/nix \
    -b ${instDir}/bin:/bin \
    -b ${instDir}/etc:/etc \
    -b ${instDir}/tmp:/tmp \
    -b ${instDir}/usr:/usr \
    -b /:/android \
    --link2symlink \
    ${instDir}/bin/sh ${instDir}/usr/lib/login-inner "$@"
''
