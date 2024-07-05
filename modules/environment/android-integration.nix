# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, lib, pkgs, ... }:

let
  cfg = config.android-integration;

  termux-am =
    pkgs.callPackage (import ../../pkgs/android-integration/termux-am.nix) { };
  termux-tools =
    pkgs.callPackage (import ../../pkgs/android-integration/termux-tools.nix) {
      inherit termux-am;
    };
in
{

  ###### interface

  options.android-integration = {

    am.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = "true";
      description = lib.mdDoc ''
        Provide an `am` (activity manager) command.
        Is not guaranteed to be a real deal, could be of limited compatibility
        with real `am` (like `termux-am`).
      '';
    };

    termux-setup-storage.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = "true";
      description = lib.mdDoc ''
        Provide a `termux-setup-storage` command
        that makes the app request storage permission,
        and then creates a $HOME/storage directory with symlinks to storage.
      '';
    };

    unsupported.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = "true";
      description = lib.mdDoc ''
        Provide several more unsupported and untested commands.
        For testing and for brave souls only.
      '';
    };

  };

  ###### implementation

  config = let ifD = cond: pkg: if cond then [ pkg ] else [ ]; in {
    environment.packages =
      (ifD cfg.am.enable termux-am) ++
      (ifD cfg.termux-setup-storage.enable termux-tools.setup_storage) ++
      (ifD cfg.unsupported.enable termux-tools.out);
  };
}
