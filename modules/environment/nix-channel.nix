# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

# Based on
# https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/config/nix-channel.nix
# (Copyright (c) 2003-2022 Eelco Dolstra and the Nixpkgs/NixOS contributors,
# licensed under MIT License as well)

{ config, lib, pkgs, nixpkgs, ... }:

with lib;

let
  cfg = config.nix;
  renameNixOpt = old: new:
    (mkRenamedOptionModule [ "nix" old ] [ "nix" new ]);
in

{
  ###### interface

  options = {

    nix = {
      nixPath = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          The default Nix expression search path, used by the Nix
          evaluator to look up paths enclosed in angle brackets
          (e.g. <literal>&lt;nixpkgs&gt;</literal>).
        '';
      };
    };

  };


  ###### implementation

  config = {
    environment.sessionVariables.NIX_PATH = concatStringsSep ":" cfg.nixPath;
  };

}
