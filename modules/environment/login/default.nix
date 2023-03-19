# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, lib, pkgs, initialPackageInfo, ... }:

with lib;

let
  cfg = config.environment.files;

  inherit (config.build) installationDir;

  login = pkgs.callPackage ./login.nix { inherit config; };
  loginInner = pkgs.callPackage ./login-inner.nix { inherit config initialPackageInfo; };
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
        description = "<literal>proot-static</literal> package.";
      };
    };

  };


  ###### implementation

  config = {

    build.activation = {
      installLogin = ''
        if ! diff ${installationDir}/bin/login ${login} > /dev/null; then
          $DRY_RUN_CMD mkdir $VERBOSE_ARG --parents ${installationDir}/bin
          $DRY_RUN_CMD cp $VERBOSE_ARG ${login} \
            ${installationDir}/bin/.login.tmp
          $DRY_RUN_CMD chmod $VERBOSE_ARG u+w \
            ${installationDir}/bin/.login.tmp
          $DRY_RUN_CMD mv $VERBOSE_ARG \
            ${installationDir}/bin/.login.tmp ${installationDir}/bin/login
        fi
      '';

      installLoginInner = ''
        if (test -e /usr/lib/.login-inner.new && ! diff /usr/lib/.login-inner.new ${loginInner} > /dev/null) || \
            (! test -e /usr/lib/.login-inner.new && ! diff /usr/lib/login-inner ${loginInner} > /dev/null); then
          $DRY_RUN_CMD mkdir $VERBOSE_ARG --parents /usr/lib
          $DRY_RUN_CMD cp $VERBOSE_ARG ${loginInner} /usr/lib/.login-inner.tmp
          $DRY_RUN_CMD chmod $VERBOSE_ARG u+w /usr/lib/.login-inner.tmp
          $DRY_RUN_CMD mv $VERBOSE_ARG /usr/lib/.login-inner.tmp /usr/lib/.login-inner.new
        fi
      '';

      installProotStatic = ''
      if (test -e ${installationDir}/bin/.proot-static.new && \
          ! diff ${installationDir}/bin/.proot-static.new \
                 ${cfg.prootStatic}/bin/proot-static > /dev/null) || \
         (! test -e ${installationDir}/bin/.proot-static.new && \
          ! diff ${installationDir}/bin/proot-static \
                 ${cfg.prootStatic}/bin/proot-static > /dev/null); then
          $DRY_RUN_CMD mkdir $VERBOSE_ARG --parents ${installationDir}/bin
          $DRY_RUN_CMD cp $VERBOSE_ARG ${cfg.prootStatic}/bin/proot-static \
            ${installationDir}/bin/.proot-static.tmp
          $DRY_RUN_CMD chmod $VERBOSE_ARG u+w \
            ${installationDir}/bin/.proot-static.tmp
          $DRY_RUN_CMD mv $VERBOSE_ARG \
            ${installationDir}/bin/.proot-static.tmp \
            ${installationDir}/bin/.proot-static.new
        fi
      '';
    };

    environment.files = {
      inherit login loginInner;

      prootStatic = "/nix/store/v009qzizi2jcywqbd3jlnmzynjvg4d2d-proot-termux-static-aarch64-unknown-linux-android-unstable-2023-02-23";
    };

  };

}
