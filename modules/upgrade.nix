# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, lib, ... }:

{
  config.build.activationAfter =
    # TODO: remove when we stop supporting upgrades from <21.11
    # Setups upgraded to 21.11 don't have the /dev/shm directory bootstrapped:
    # https://github.com/nix-community/nix-on-droid/issues/162
    lib.mkIf (lib.versionOlder config.system.stateVersion "21.11") {
      createDevShm = ''
        mkdir -p ${config.build.installationDir}/dev/shm
      '';
    };
}
