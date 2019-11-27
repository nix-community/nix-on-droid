# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ config, lib, pkgs, customPkgs, ... }:

with lib;

let
  cfg = config.environment.files;

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

      prootStatic = mkOption {
        type = types.package;
        readOnly = true;
        internal = true;
        description = "proot-static package.";
      };
    };

  };


  ###### implementation

  config = {

    build.activation = {
      installLoginScripts = ''
        $DRY_RUN_CMD mkdir $VERBOSE_ARG --parents /bin /usr/lib
        $DRY_RUN_CMD cp $VERBOSE_ARG ${login} /bin/login
        $DRY_RUN_CMD cp $VERBOSE_ARG ${loginInner} /usr/lib/login-inner
      '';

      installProotStatic = ''
        $DRY_RUN_CMD mkdir $VERBOSE_ARG --parents /bin
        $DRY_RUN_CMD cp $VERBOSE_ARG ${cfg.prootStatic}/bin/proot-static /bin/.proot-static.new
      '';
    };

    environment.files = {
      inherit login loginInner;

      prootStatic =
        if config.build.arch == "aarch64"
        then "/nix/store/40zq5iy3iaj3pc9phshxmp4x8k7084lf-proot-termux-unstable-2019-09-05-aarch64-unknown-linux-android"
        else "/nix/store/wlr4f16mfsg1fkj4wdrppcmh0kd3lgwv-proot-termux-unstable-2019-09-05-i686-unknown-linux-android";
    };

  };

}
