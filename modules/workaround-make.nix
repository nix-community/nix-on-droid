# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.system.workaround.make-posix-spawn;

  gnumake-no-posix-spawn = pkgs.gnumake.overrideAttrs (old: {
    configureFlags = old.configureFlags ++ [ "--disable-posix-spawn" ];

    buildPhase = "${pkgs.gnumake42}/bin/make";
    installPhase = ''
      mkdir -p $out
      ${pkgs.gnumake42}/bin/make install
    '';

    # make a copy to facilitate repairs when it gets broken
    # because of being bind-mounted onto the normal make
    postFixup = ''
      cp $out/bin/make $out/bin/overlaying-make
      touch $out/SEE_system.workaround.make-posix-spawn.enable
    '';
  });
in
{

  ###### interface

  options = {

    system.workaround.make-posix-spawn.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        On some devices, GNU make 4.3 fails with 'Function not implemented',
        and the workaround is to compile it with '--disable-posix-spawn'.
        This option will shadow the original make in a really dirty way,
        by overlaying broken gnumake with a fixed version on proot level.
        Please only enable this for a limited time:
        get stuck with a broken build; stop attempting to build something;
        enable the option; nix-on-droid switch, relogin, build,
        disable the option; nix-on-droid switch, relogin.

        If you leave it on, Nix-store validation will fail,
        repairs will break the working make,
        updates will do bad things. You have been warned.

        If you find yourself needing that hack, please report details at
        https://github.com/t184256/nix-on-droid/issues/91
        and consider building remotely as an alternative for such devices:
        https://github.com/t184256/nix-on-droid/wiki/Remote-building
      '';
    };

  };

  ###### implementation

  config = {
    build.extraProotOptions =
      lib.optionals cfg.enable [
        "-b"
        (
          "${config.build.installationDir}/"
          + "${gnumake-no-posix-spawn}/bin/overlaying-make"
          + ":${pkgs.gnumake}/bin/make"
        )
      ];
  };
}
