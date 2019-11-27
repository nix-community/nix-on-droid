# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ config, lib, pkgs, customPkgs, ... }:

with lib;

let
  login = pkgs.callPackage ./login.nix { inherit config; };

  loginInner = pkgs.callPackage ./login-inner.nix { inherit config customPkgs; };
in

{

  ###### interface

  options = {

    environment.files = {
      login = mkOption {
        type = types.package;
        readOnly = true;
        internal = true;
        description = "Login script.";
      };

      loginInner = mkOption {
        type = types.package;
        readOnly = true;
        internal = true;
        description = "Login-inner script.";
      };
    };

  };


  ###### implementation

  config = {

    build.activation.installLoginScripts = ''
      $DRY_RUN_CMD mkdir $VERBOSE_ARG --parents /bin /usr/lib
      $DRY_RUN_CMD cp $VERBOSE_ARG ${login} /bin/login
      $DRY_RUN_CMD cp $VERBOSE_ARG ${loginInner} /usr/lib/login-inner
    '';

    environment.files = {
      inherit login loginInner;
    };

  };

}
