{ pkgs ? import <nixpkgs> { } }:

rec {
  nix-on-droid = pkgs.callPackage ./nix-on-droid { };

  basic-environment = pkgs.runCommand
    "basic-environment-2.0"
    {
      preferLocalBuild = true;
      allowSubstitutes = false;
    }
    ''
      echo
      echo "===================================================="
      echo
      echo "You are currently using an old installation of nix-on-droid. The way it manages your device has changed \
      from installing the basic-environment package to a real module system. For more information see \
      https://github.com/t184256/nix-on-droid-bootstrap."
      echo
      echo "You can either reinstall the app or run"
      echo "  nix-shell '<nix-on-droid>' -A migration"
      echo "to migrate your system to the new version."
      echo
      echo "Please note, that all files in /etc currently provided by nix-on-droid will be created. The current files \
      will be backed up with a '.bak' file extension."
      echo
      echo "For setups with home-manager (only recognised if HOME_MANAGER_CONFIG is set or ~/.config/nixpkgs/home.nix \
      is present) there is one manual step necessary *before* running the migration script: Remove basic-environment \
      package of 'home.packages' list."
      echo
      echo "===================================================="
      echo
      exit 1
    '';

  migration = pkgs.runCommand
    "migration"
    {
      preferLocalBuild = true;
      allowSubstitutes = false;
      shellHookOnly = true;
      shellHook = ''
        set -eu -o pipefail

        export GC_NPROCS=1  # to prevent gc warnings of nix, see https://github.com/NixOS/nix/issues/3237

        echo "Installing nix-on-droid.nix default config file..."
        ${pkgs.coreutils}/bin/mkdir --parents $HOME/.config/nixpkgs
        ${pkgs.coreutils}/bin/cp ${./modules/environment/login/nix-on-droid.nix.default} $HOME/.config/nixpkgs/nix-on-droid.nix
        ${pkgs.coreutils}/bin/chmod u+w $HOME/.config/nixpkgs/nix-on-droid.nix

        if command -v home-manager > /dev/null && [[ -n "''${HOME_MANAGER_CONFIG:-}" && -r "$HOME_MANAGER_CONFIG" || -r "$HOME/.config/nixpkgs/home.nix" ]]; then
          echo "Migrating home-manager installation..."
          if [[ -r "$HOME/.config/nixpkgs/home.nix" ]]; then
            ${pkgs.patch}/bin/patch --no-backup-if-mismatch $HOME/.config/nixpkgs/nix-on-droid.nix ${pkgs.writeText "patch" ''
              @@ -27,15 +27,9 @@
                 # Read the changelog before changing this value
                 system.stateVersion = "19.09";

              -  # After installing home-manager channel like
              -  #   nix-channel --add https://github.com/rycee/home-manager/archive/release-19.09.tar.gz home-manager
              -  #   nix-channel --update
              -  # you can configure home-manager in here like
              -  #home-manager.config =
              -  #  { pkgs, ... }:
              -  #  {
              -  #    # insert home-manager config
              -  #  };
              +  # Home Manager config file
              +  home-manager.config = import ./home.nix;
              +  home-manager.useUserPackages = true;
               }

               # vim: ft=nix
            ''} > /dev/null
          else
            ${pkgs.patch}/bin/patch --no-backup-if-mismatch $HOME/.config/nixpkgs/nix-on-droid.nix ${pkgs.writeText "patch" ''
              @@ -27,15 +27,9 @@
                 # Read the changelog before changing this value
                 system.stateVersion = "19.09";

              -  # After installing home-manager channel like
              -  #   nix-channel --add https://github.com/rycee/home-manager/archive/release-19.09.tar.gz home-manager
              -  #   nix-channel --update
              -  # you can configure home-manager in here like
              -  #home-manager.config =
              -  #  { pkgs, ... }:
              -  #  {
              -  #    # insert home-manager config
              -  #  };
              +  # Home Manager config file
              +  home-manager.config = import (builtins.getEnv "HOME_MANAGER_CONFIG");
              +  home-manager.useUserPackages = true;
               }

               # vim: ft=nix
            ''} > /dev/null
          fi

          echo "Uninstall home-manager-path..."
          ${pkgs.nix}/bin/nix-env --uninstall home-manager-path
        fi

        echo "Decrease priority of basic-environment..."
        ${pkgs.nix}/bin/nix-env --set-flag priority 120 basic-environment

        echo "Install first nix-on-droid generation..."
        ${nix-on-droid}/bin/nix-on-droid switch

        echo "Uninstall basic-environment..."
        ${pkgs.nix}/bin/nix-env --uninstall basic-environment

        echo "Installation successful! Please restart the app to complete the migration as starting new sessions will fail."
        exit 0
      '';
    }
    ''
      echo "This derivation is not buildable, instead run it using nix-shell."
      exit 1
    '';
}
