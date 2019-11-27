# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ config, lib, customPkgs, writeText }:

let
  inherit (customPkgs.packageInfo) cacert coreutils nix;
in

writeText "login-inner" ''
  set -e

  [ "$#" -gt 0 ] || echo "Welcome to Nix-on-Droid!"

  [ "$#" -gt 0 ] || echo "If nothing works, use the rescue shell and read ${config.build.installationDir}/usr/lib/login-inner"
  [ "$#" -gt 0 ] || echo "If it does not help, report bugs at https://github.com/t184256/nix-on-droid-bootstrap/issues"

  export USER="${config.user.userName}"
  export HOME="${config.user.home}"

  export GC_NPROCS=1  # to prevent gc warnings of nix, see https://github.com/NixOS/nix/issues/3237

  ${lib.optionalString config.build.initialBuild ''
    # link needed to force nix-env -i to install in the user profile
    ${coreutils}/bin/ln --symbolic /nix/var/nix/profiles/per-user/$USER/profile $HOME/.nix-profile

    [ "$#" -gt 0 ] || echo "Sourcing Nix environment..."
    . ${nix}/etc/profile.d/nix.sh

    export NIX_SSL_CERT_FILE=${cacert}

    echo "Installing and updating nix-channels..."
    ${nix}/bin/nix-channel --add ${config.build.channel.nixpkgs} nixpkgs
    ${nix}/bin/nix-channel --update nixpkgs
    ${nix}/bin/nix-channel --add ${config.build.channel.nix-on-droid} nix-on-droid
    ${nix}/bin/nix-channel --update nix-on-droid

    echo "Copy default nix-on-droid config..."
    ${coreutils}/bin/mkdir --parents $HOME/.config/nixpkgs
    ${coreutils}/bin/cp /etc/nix-on-droid.nix.default $HOME/.config/nixpkgs/nix-on-droid.nix

    echo "Installing first nix-on-droid generation..."
    ${nix}/bin/nix build --no-link --file "<nix-on-droid>" nix-on-droid
    $(${nix}/bin/nix path-info --file "<nix-on-droid>" nix-on-droid)/bin/nix-on-droid switch

    echo
    echo "Congratulations! Now you have Nix installed with some default packages like bashInteractive, \
    coreutils, cacert and most important nix-on-droid itself to manage local configuration, see"
    echo "  nix-on-droid help"
    echo "or in the config file"
    echo "  ~/.config/nixpkgs/nix-on-droid.nix"
    echo
    echo "You can go for the bare nix-on-droid setup or you can configure your phone via home-manager. See \
    config file for further information."
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
