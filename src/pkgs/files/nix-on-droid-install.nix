# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ instDir, packageInfo, writeScript }:

writeScript "nix-on-droid-install" ''
  #!/bin/sh
  set -e

  if [ -e $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh ]; then
    echo "You already have home-manager installed."
  fi

  echo "Installing home-manager and other good stuff..."

  echo "Subscribing to the stable (nixos-19.03) channel of nixpkgs..."
  echo "If you want unstable instead, you probably also know what to do."
  ${packageInfo.nix}/bin/nix-channel --add https://nixos.org/channels/nixos-19.03 nixpkgs
  echo "Subscribing to home-manager channel..."
  ${packageInfo.nix}/bin/nix-channel --add https://github.com/rycee/home-manager/archive/master.tar.gz home-manager
  echo "Updating channels..."
  ${packageInfo.nix}/bin/nix-channel --update
  echo "Whew."

  export NIX_PATH=$HOME/.nix-defexpr/channels''${NIX_PATH:+:}$NIX_PATH

  if [ ! -e $HOME/.config/nixpkgs/home.nix ]; then
    echo "Creating an initial home-manager configuration in ~/.config/nixpkgs/home.nix ..."
    ${packageInfo.nix}/bin/nix run nixpkgs.coreutils -c mkdir -p $HOME/.config/nixpkgs/
    ${packageInfo.nix}/bin/nix run nixpkgs.coreutils -c cp -n ${instDir}/etc/home.nix.default $HOME/.config/nixpkgs/home.nix
  fi

  echo "Installing home-manager..."
  ${packageInfo.nix}/bin/nix run nixpkgs.nix -c ${packageInfo.nix}/bin/nix-shell '<home-manager>' -A install

  echo "Edit ~/.config/nixpkgs/home.nix and home-manager rebuild to control what is going on."
  echo "Run bash or restart your session to enjoy a much nicer environment."
''
