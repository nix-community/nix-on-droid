# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ initialBuild, instDir, packageInfo, writeTextDir }:

writeTextDir "usr/lib/login-inner" ''
  set -e

  [ "$#" -gt 0 ] || echo "Welcome to Nix-on-Droid!"

  [ "$#" -gt 0 ] || echo "If nothing works, use the rescue shell and read ${instDir}/usr/lib/login-inner"
  [ "$#" -gt 0 ] || echo "If it does not help, report bugs at https://github.com/t184256/nix-on-droid-bootstrap/issues"

  export USER=nix-on-droid
  export HOME="/data/data/com.termux.nix/files/home"

  ${
    if initialBuild
    then ''
      [ "$#" -gt 0 ] || echo "Sourcing Nix environment..."
      . ${packageInfo.nix}/etc/profile.d/nix.sh

      export NIX_SSL_CERT_FILE=${packageInfo.cacert}

      echo "Installing and updating nix-channels..."
      ${packageInfo.nix}/bin/nix-channel --add https://nixos.org/channels/nixos-19.03 nixpkgs
      ${packageInfo.nix}/bin/nix-channel --add https://github.com/t184256/nix-on-droid-bootstrap/archive/master.tar.gz nix-on-droid
      ${packageInfo.nix}/bin/nix-channel --update

      echo "Installing nix-on-droid.basic-environment..."
      ${packageInfo.nix}/bin/nix-env -iA nix-on-droid.basic-environment

      echo "Setting up dynamic symlinks via nix-on-droid-linker"
      nix-on-droid-linker

      echo
      echo "Congratulations! Now you have Nix installed with some basic packages like"
      echo "bashInteractive, coreutils, cacert and some scripts provided by nix-on-droid"
      echo "itself."
      echo
      echo "You can go for the bare Nix setup or you can configure your phone via"
      echo "home-manager. For that simply run hm-install."
      echo
    ''
    else ''
      [ "$#" -gt 0 ] || echo "Sourcing Nix environment..."
      . $HOME/.nix-profile/etc/profile.d/nix.sh
    ''
  }

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
