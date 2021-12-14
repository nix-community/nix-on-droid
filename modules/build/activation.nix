# Copyright (c) 2019-2021, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.build;

  profileDirectory = "/nix/var/nix/profiles/nix-on-droid";

  # Programs that always should be available on the activation
  # script's PATH.
  activationBinPaths = lib.makeBinPath [
    pkgs.bash
    pkgs.coreutils
    pkgs.diffutils
    pkgs.findutils
    pkgs.gnugrep
    pkgs.gnused
    pkgs.ncurses          # For `tput`.
    config.nix.package
  ];

  mkActivationCmds = activation: concatStringsSep "\n" (
    mapAttrsToList (name: value: ''
      noteEcho "Activating ${name}"
      ${value}
    '') activation
  );

  activationScript = pkgs.writeScript "activation-script" ''
    #!${pkgs.runtimeShell}

    set -eu
    set -o pipefail

    export PATH="${activationBinPaths}"
    _NOD_GENERATION_DIR="$(realpath "$(dirname "$0")")"
    cd "$HOME"

    ${builtins.readFile ../lib-bash/color-echo.sh}
    ${builtins.readFile ../lib-bash/activation-init.sh}

    ${mkActivationCmds cfg.activationBefore}
    ${mkActivationCmds cfg.activation}
    ${mkActivationCmds cfg.activationAfter}
  '';

  activationOptionDescriptionSuffix = ''
    </para><para>

    Any script should respect the <varname>DRY_RUN</varname>
    variable, if it is set then no actual action should be taken.
    The variable <varname>DRY_RUN_CMD</varname> is set to
    <code>echo</code> if dry run is enabled. Thus, many cases you
    can use the idiom <code>$DRY_RUN_CMD rm -rf /</code>.

    </para><para>

    Any script block should also respect the
    <varname>VERBOSE</varname> variable, and if set print
    information on standard out that may be useful for debugging
    any issue that may arise. The variable
    <varname>VERBOSE_ARG</varname> is set to
    <option>--verbose</option> if verbose output is enabled.
    The variable <varname>VERBOSE_ECHO</varname> is set to
    <code>echo</code> if verbose output is enabled, otherwise
    falling back to <code>true</code>. So it can be used like
    <code>$VERBOSE_ECHO "any message"</code>.
  '';
in

{

  ###### interface

  options = {

    build = {
      activation = mkOption {
        default = {};
        type = types.attrs;
        description = ''
          Activation scripts for the nix-on-droid environment.
        '' + activationOptionDescriptionSuffix;
      };

      activationBefore = mkOption {
        default = {};
        type = types.attrs;
        description = ''
          Activation scripts for the nix-on-droid environment that
          need to be run first.
        '' + activationOptionDescriptionSuffix;
      };

      activationAfter = mkOption {
        default = {};
        type = types.attrs;
        description = ''
          Activation scripts for the nix-on-droid environment that
          need to be run last.
        '' + activationOptionDescriptionSuffix;
      };

      activationPackage = mkOption {
        type = types.package;
        readOnly = true;
        internal = true;
        description = "Derivation with activation script.";
      };

      etc = mkOption {
        type = types.package;
        internal = true;
        description = "Package containing /etc files.";
      };

      sessionInit = mkOption {
        type = types.path;
        internal = true;
        description = "File containing session init commands like exposing environment variables.";
      };
    };

  };


  ###### implementation

  config = {

    build = {
      activationAfter.linkProfile = ''
        generationDir="$(dirname $0)"

        if [[ $generationDir =~ ^${profileDirectory}-([0-9]+)-link$ ]]; then
          $DRY_RUN_CMD nix-env --profile "${profileDirectory}" --switch-generation "''${BASH_REMATCH[1]}"
        else
          $DRY_RUN_CMD nix-env --profile "${profileDirectory}" --set "$_NOD_GENERATION_DIR"
        fi
      '';

      activationPackage =
        pkgs.runCommand
          "nix-on-droid-generation"
          {
            preferLocalBuild = true;
            allowSubstitutes = false;
          }
          ''
            mkdir --parents $out/filesystem/{bin,usr/{bin,lib}}

            cp ${activationScript} $out/activate

            ln --symbolic ${config.build.etc}/etc $out/etc
            ln --symbolic ${config.environment.path} $out/nix-on-droid-path

            ln --symbolic ${config.environment.files.login} $out/filesystem/bin/login
            ln --symbolic ${config.environment.files.loginInner} $out/filesystem/usr/lib/login-inner
            ln --symbolic ${config.environment.files.prootStatic}/bin/proot-static $out/filesystem/bin/proot-static

            ln --symbolic ${config.environment.binSh} $out/filesystem/bin/sh
            ln --symbolic ${config.environment.usrBinEnv} $out/filesystem/usr/bin/env
          '';
    };

  };

}
