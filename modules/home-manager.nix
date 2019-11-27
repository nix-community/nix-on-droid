# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.home-manager;

  hmModule = types.submodule ({ name, ... }: {
    imports = import <home-manager/modules/modules.nix> { inherit lib pkgs; };

    config = {
      submoduleSupport.enable = true;
      submoduleSupport.externalPackageInstall = cfg.useUserPackages;

      home.username = config.user.userName;
      home.homeDirectory = config.user.home;
    };
  });
in

{

  ###### interface

  options = {

    home-manager = {
      config = mkOption {
        type = types.nullOr hmModule;
        default = null;
        description = "Home Manager configuration.";
      };

      useUserPackages = mkEnableOption ''
        installation of user packages through the
        <option>environment.packages</option> option.
      '';
    };

  };


  ###### implementation

  config = mkIf (cfg.config != null) {

    inherit (cfg.config) assertions warnings;

    build.activation.homeManager = ''
      ${cfg.config.home.activationPackage}/activate
    '';

    environment.packages = mkIf cfg.useUserPackages cfg.config.home.packages;

  };
}
