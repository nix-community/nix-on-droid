# Copyright (c) 2019-2021, see AUTHORS. Licensed under MIT License, see LICENSE.

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
      installLogin = ''
        if ! diff /bin/login ${login} > /dev/null; then
          $DRY_RUN_CMD mkdir $VERBOSE_ARG --parents /bin
          $DRY_RUN_CMD cp $VERBOSE_ARG ${login} /bin/.login.tmp
          $DRY_RUN_CMD chmod $VERBOSE_ARG u+w /bin/.login.tmp
          $DRY_RUN_CMD mv $VERBOSE_ARG /bin/.login.tmp /bin/login
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
        if (test -e /bin/.proot-static.new && ! diff /bin/.proot-static.new ${cfg.prootStatic}/bin/proot-static > /dev/null) || \
            (! test -e /bin/.proot-static.new && ! diff /bin/proot-static ${cfg.prootStatic}/bin/proot-static > /dev/null); then
          $DRY_RUN_CMD mkdir $VERBOSE_ARG --parents /bin
          $DRY_RUN_CMD cp $VERBOSE_ARG ${cfg.prootStatic}/bin/proot-static /bin/.proot-static.tmp
          $DRY_RUN_CMD chmod $VERBOSE_ARG u+w /bin/.proot-static.tmp
          $DRY_RUN_CMD mv $VERBOSE_ARG /bin/.proot-static.tmp /bin/.proot-static.new
        fi
      '';
    };

    environment.files = {
      inherit login loginInner;

      prootStatic =
        let
          crossCompiledPaths = {
           aarch64 = "/nix/store/0xfjhi3529lzym7z7025xs7kignmgy0r-proot-termux-aarch64-unknown-linux-android-unstable-2020-10-25";
           i686 = "/nix/store/jl91v6ya3ablh8v41k63vcwsim5b4v1s-proot-termux-i686-unknown-linux-android-unstable-2020-10-25";
          };
        in
          "${crossCompiledPaths.${config.build.arch}}";
    };

  };

}
