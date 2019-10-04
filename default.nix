# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ pkgs ? import <nixpkgs> { } }:

rec {
  basic-environment = pkgs.buildEnv {
    name = "basic-environment";

    paths = with pkgs; [
      bashInteractive
      cacert
      coreutils
      hm-install
      nix
      nix-on-droid-linker
    ];
  };

  hm-install = pkgs.writeScriptBin "hm-install" ''
    #!/usr/bin/env sh
    set -e

    if [ -e $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh ]; then
      echo "You already have home-manager installed."
    fi

    echo "Subscribing to home-manager channel..."
    ${pkgs.nix}/bin/nix-channel --add https://github.com/rycee/home-manager/archive/master.tar.gz home-manager
    echo "Updating channels..."
    ${pkgs.nix}/bin/nix-channel --update

    export NIX_PATH=$HOME/.nix-defexpr/channels''${NIX_PATH:+:}$NIX_PATH

    if [ ! -e $HOME/.config/nixpkgs/home.nix ]; then
      echo "Creating an initial home-manager configuration in ~/.config/nixpkgs/home.nix ..."
      ${pkgs.coreutils}/bin/mkdir -p $HOME/.config/nixpkgs
      ${pkgs.coreutils}/bin/cp -n /etc/home.nix.default $HOME/.config/nixpkgs/home.nix
    fi

    echo "Uninstalling basic-environment..."
    ${pkgs.nix}/bin/nix-env --uninstall basic-environment
    echo "Installing home-manager..."
    ${pkgs.nix}/bin/nix run nixpkgs.nix -c ${pkgs.nix}/bin/nix-shell '<home-manager>' -A install
  '';

  nix-on-droid-linker = pkgs.writeScriptBin "nix-on-droid-linker" ''
    #!/usr/bin/env sh
    set -e

    echo "Linking ~/.nix-profile/bin/sh to /bin/sh"
    ${pkgs.coreutils}/bin/ln -snf $HOME/.nix-profile/bin/sh /bin/sh
    echo "Linking ~/.nix-profile/usr/bin/env to /usr/bin/env"
    ${pkgs.coreutils}/bin/ln -snf $HOME/.nix-profile/bin/env /usr/bin/env
  '';
}
