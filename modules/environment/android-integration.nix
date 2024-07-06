# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, lib, pkgs, nixpkgs, ... }:

let
  cfg = config.android-integration;

  termux-am =
    pkgs.callPackage (import ../../pkgs/android-integration/termux-am.nix) { };
  termux-tools =
    pkgs.callPackage (import ../../pkgs/android-integration/termux-tools.nix) {
      inherit termux-am;
    };
  okc-agents =
    import (../../pkgs/android-integration/okc-agents) {
      inherit nixpkgs pkgs termux-am;
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

    termux-open.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = "true";
      description = lib.mdDoc ''
        Provide a `termux-open` command
        that opens files or urls in external apps
        (uses `com.termux.app.TermuxOpenReceiver`).
      '';
    };

    termux-open-url.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = "true";
      description = lib.mdDoc ''
        Provide a `termux-open-url` command
        that opens files or urls in external apps
        (uses `android.intent.action.VIEW`).
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

    termux-reload-settings.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = "true";
      description = lib.mdDoc ''
        Provide a `termux-reload-settings` command
        which applies changes to font, colorscheme or terminal
        without the need to close all the sessions.
      '';
    };

    termux-wake-lock.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = "true";
      description = lib.mdDoc ''
        Provide a `termux-wake-lock` command
        that tones down Android power saving measures.
        This is the same action that's available from the notification.
      '';
    };

    termux-wake-unlock.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = "true";
      description = lib.mdDoc ''
        Provide a `termux-wake-unlock` command
        that undoes the effect of the `termux-wake-lock` one.
      '';
    };

    xdg-open.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = "true";
      description = lib.mdDoc ''
        Provide an `xdg-open` alias to `termux-open` command.
      '';
    };

    okc-gpg.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = "true";
      description = lib.mdDoc ''
        Provides a GPG agent for OpenKeychain,
        courtesy of https://github.com/DDoSolitary/okc-agents.
        This lets you use PGP keys stored on hardware tokens, like Yubikeys.
      '';
    };

    unsupported.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = "true";
      description = lib.mdDoc ''
        Provide several more unsupported and untested commands.
        For testing and for brave souls only.
        Currently provides `termux-backup` and `okc-ssh-agent`.
      '';
    };

  };

  ###### implementation

  config = let ifD = cond: pkg: if cond then [ pkg ] else [ ]; in {
    environment.packages =
      (ifD cfg.am.enable termux-am) ++
      (ifD cfg.termux-setup-storage.enable termux-tools.setup_storage) ++
      (ifD cfg.termux-open.enable termux-tools.open) ++
      (ifD cfg.termux-open-url.enable termux-tools.open_url) ++
      (ifD cfg.termux-reload-settings.enable termux-tools.reload_settings) ++
      (ifD cfg.termux-wake-lock.enable termux-tools.wake_lock) ++
      (ifD cfg.termux-wake-unlock.enable termux-tools.wake_unlock) ++
      (ifD cfg.xdg-open.enable termux-tools.xdg_open) ++
      (ifD cfg.okc-gpg.enable okc-agents.okc_gpg) ++
      (ifD cfg.unsupported.enable okc-agents.out) ++
      (ifD cfg.unsupported.enable termux-tools.out);
  };
}
