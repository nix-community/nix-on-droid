# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, lib, pkgs, ... }:

let
  cfg = config.android-integration;

  termux-am =
    pkgs.callPackage (import ../../pkgs/android-integration/termux-am.nix) { };
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

  };

  ###### implementation

  config = {
    environment.packages =
      lib.mkIf cfg.am.enable [ termux-am ];
  };
}
