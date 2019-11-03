# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ config, lib, packageInfo, writeTextDir }:

writeTextDir "usr/lib/login-inner" ''
  set -e

  [ "$#" -gt 0 ] || echo "Welcome to Nix-on-Droid!"

  [ "$#" -gt 0 ] || echo "If nothing works, use the rescue shell and read ${config.core.installation}/usr/lib/login-inner"
  [ "$#" -gt 0 ] || echo "If it does not help, report bugs at https://github.com/t184256/nix-on-droid-bootstrap/issues"

  export USER="${config.user.user}"
  export HOME="${config.user.home}"

  ${lib.optionalString config.core.initialBuild ''
    [ "$#" -gt 0 ] || echo "Sourcing Nix environment..."
    . ${packageInfo.nix}/etc/profile.d/nix.sh

    export NIX_SSL_CERT_FILE=${packageInfo.cacert}

    echo "Installing and updating nix-channels..."
    ${packageInfo.nix}/bin/nix-channel --add ${config.channel.nixpkgs} nixpkgs
    ${packageInfo.nix}/bin/nix-channel --add ${config.channel.nix-on-droid} nix-on-droid
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
  ''}

  [ "$#" -gt 0 ] || echo "Sourcing Nix environment..."
  . $HOME/.nix-profile/etc/profile.d/nix.sh

  if [ -e "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
    [ "$#" -gt 0 ] || echo "Sourcing home-manager environment..."
    export NIX_PATH=$HOME/.nix-defexpr/channels''${NIX_PATH:+:}$NIX_PATH
    . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
  fi

  # Workaround for https://github.com/NixOS/nix/issues/1865
  export NIX_PATH=nixpkgs=$HOME/.nix-defexpr/channels/nixpkgs/:$NIX_PATH

  if [ "$#" -eq 0 ]; then
    exec /usr/bin/env bash
  else
    exec /usr/bin/env "$@"
  fi
''
