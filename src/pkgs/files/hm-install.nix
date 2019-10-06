# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ coreutils, instDir, nix, writeScriptBin }:

writeScriptBin "hm-install" ''
  #!/usr/bin/env sh
  set -e

  if [ -e $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh ]; then
    echo "You already have home-manager installed."
  fi

  echo "Subscribing to home-manager channel..."
  ${nix}/bin/nix-channel --add https://github.com/rycee/home-manager/archive/master.tar.gz home-manager
  echo "Updating channels..."
  ${nix}/bin/nix-channel --update

  export NIX_PATH=$HOME/.nix-defexpr/channels''${NIX_PATH:+:}$NIX_PATH

  if [ ! -e $HOME/.config/nixpkgs/home.nix ]; then
    echo "Creating an initial home-manager configuration in ~/.config/nixpkgs/home.nix ..."
    ${coreutils}/bin/mkdir -p $HOME/.config/nixpkgs
    ${coreutils}/bin/cp -n /etc/home.nix.default $HOME/.config/nixpkgs/home.nix
  fi

  ${nix}/bin/nix-env --set-flag priority 120 basic-environment

  echo "Installing home-manager..."
  ${nix}/bin/nix run nixpkgs.nix -c ${nix}/bin/nix-shell '<home-manager>' -A install

  echo "home-manager is installed. Please, restart the session."
''
