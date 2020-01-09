# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, lib, pkgs, ... }:

with lib;

{

  ###### interface

  options = {

  };


  ###### implementation

  config = {

    environment.etc = {
      "nix/nix.conf".text = ''
        sandbox = false
        substituters = https://cache.nixos.org https://nix-on-droid.cachix.org
        trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-on-droid.cachix.org-1:56snoMJTXmDRC1Ei24CmKoUqvHJ9XCp+nidK7qkMQrU=
      '';

      "resolv.conf".text = ''
        nameserver 1.1.1.1
        nameserver 8.8.8.8
      '';
    };

  };

}
