# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ instDir, packageInfo, writeText }:

writeText "login-inner" ''
  set -e

  [ "$#" -gt 1 ] || echo "Welcome to Nix-on-Droid!"

  [ "$#" -gt 1 ] || echo "If nothing works, use the rescue shell and read ${instDir}/bin/.login-inner"
  [ "$#" -gt 1 ] || echo "If it does not help, report bugs at https://github.com/t184256/nix-on-droid-bootstrap/issues"

  export USER="$1"
  export HOME="/data/data/com.termux.nix/files/home"
  shift

  [ "$#" -gt 0 ] || echo "Sourcing Nix environment..."
  . ${packageInfo.nix}/etc/profile.d/nix.sh

  if [ -e ${instDir}/etc/UNINTIALISED ]; then
    export NIX_SSL_CERT_FILE=${packageInfo.cacert}

    echo "Installing and updating nix-channels..."
    ${packageInfo.nix}/bin/nix-channel --add https://nixos.org/channels/nixos-19.03 nixpkgs
    ${packageInfo.nix}/bin/nix-channel --add https://github.com/t184256/nix-on-droid-bootstrap/archive/master.tar.gz nix-on-droid
    ${packageInfo.nix}/bin/nix-channel --update

    echo "Installing nix-on-droid.basic-environment..."
    ${packageInfo.nix}/bin/nix-env -iA nix-on-droid.basic-environment

    echo "Setting up static symlinks via nix-on-droid-linker"
    nix-on-droid-linker

    ${packageInfo.coreutils}/bin/rm /etc/UNINTIALISED

    echo
    echo "Congratulations! Now you have Nix installed with some basic packages like"
    echo "bashInteractive, coreutils, cacert and some scripts provided by nix-on-droid"
    echo "itself."
    echo
    echo "You can go for the bare Nix setup or you can configure your phone via"
    echo "home-manager. For that simply run hm-install."
    echo
  fi

  if [ -e "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
    [ "$#" -gt 0 ] || echo "Sourcing home-manager environment..."
    export NIX_PATH=$HOME/.nix-defexpr/channels''${NIX_PATH:+:}$NIX_PATH
    . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
  fi

  if [ "$#" -eq 0 ]; then
    exec /usr/bin/env bash
  else
    exec /usr/bin/env "$@"
  fi
''
