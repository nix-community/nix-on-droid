{ instDir, packageInfo, writeScript }:

writeScript "login-inner" ''
  set -e

  [ "$#" -gt 1 ] || echo "Welcome to Nix-on-Droid!"

  [ "$#" -gt 1 ] || echo "If nothing works, use the rescue shell and read ${instDir}/bin/.login-inner"
  [ "$#" -gt 1 ] || echo "If it does not help, report bugs at https://github.com/t184256/nix-on-droid-bootstrap/issues"

  export USER="$1"
  export HOME="/data/data/com.termux.nix/files/home"
  shift

  [ "$#" -gt 0 ] || echo "Sourcing Nix environment..."
  . ${instDir}/${packageInfo.nix}/etc/profile.d/nix.sh

  if [ ! -e $HOME/.nix-profile/etc/ssl/certs/ca-bundle.crt ]; then
    if [ -e ${packageInfo.cacert} ]; then
      export NIX_SSL_CERT_FILE=${packageInfo.cacert}
    fi
  fi

  if [ -e "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
    [ "$#" -gt 0 ] || echo "Sourcing home-manager environment..."
    export NIX_PATH=$HOME/.nix-defexpr/channels''${NIX_PATH:+:}$NIX_PATH
    . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
  fi

  if [ "$#" -eq 0 ]; then
    if [ ! -e "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
      echo "Congratulations. Now you have Nix installed, but that's kinda it."
      echo "Hope you're a seasoned Nix user, because stuff is not pretty yet."
      echo "If you wonder what to do next, and want to do it the hard way, start with running"
      echo "  nix-channel --add https://nixos.org/channels/nixos-19.03 nixpkgs"
      echo "  nix-channel --update"
      echo "After that you can summon software from nixpkgs (e.g. gitMinimal):"
      echo "* by asking for a shell that has it:"
      echo "    nix run nixpkgs.bashInteractive nixpkgs.gitMinimal"
      echo "* or installing it into the user environment (not recommended):"
      echo "    nix-env -iA nixpkgs.gitMinimal"
      echo "* or, the best way, declaratively with home-manager:"
      echo "    0. nix-on-droid-install"
      echo "    1. [get an editor and edit ~/.config/nixpkgs/home.nix]"
      echo "    2. home-manager switch"
      echo "or a myriad other ways."
      echo "You should really consider installing at least: nix, cacert and coreutils."
      echo "bashInteractive and a text editor should be high on the list too."
      echo
      echo "If you want the easy way, nix-on-droid-install should get all this covered."
      echo
      echo "TL;DR: run nix-on-droid-install and things will get better."
      echo
      echo "Dropping you into an extremely limited shell (that has Nix though). Happy hacking!"
      export PATH="${packageInfo.nix}/bin:$PATH"
      exec /bin/sh
    fi

    echo "Dropping you into a shell. Happy hacking!"
    exec /usr/bin/env bash
  else
    exec /usr/bin/env "$@"
  fi
''
