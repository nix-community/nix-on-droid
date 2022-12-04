# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, lib, ... }:

with lib;

let
  cfg = config.terminal;
in

{

  ###### interface

  options = {

    terminal.font = mkOption {
      default = null;
      type = types.nullOr types.path;
      example = lib.literalExpression
        ''"''${pkgs.terminus_font_ttf}/share/fonts/truetype/TerminusTTF.ttf"'';
      description = ''
        Font used for the terminal.
      '';
    };

  };


  ###### implementation

  config = {

    build.activation =
      let
        fontPath =
          if (lib.strings.hasPrefix "/nix" cfg.font)
          then "${config.build.installationDir}/${cfg.font}"
          else cfg.font;
        configDir = "${config.user.home}/.termux";
        fontTarget = "${configDir}/font.ttf";
        fontBackup = "${configDir}/font.ttf.bak";
      in
      if (cfg.font != null) then
        {
          linkFont = ''
            $DRY_RUN_CMD mkdir $VERBOSE_ARG -p "${configDir}"
            if [ -e "${fontTarget}" ] && ! [ -L "${fontTarget}" ]; then
              $DRY_RUN_CMD mv $VERBOSE_ARG "${fontTarget}" "${fontBackup}"
              $DRY_RUN_CMD echo "${fontTarget} has been moved to ${fontBackup}"
            fi
            $DRY_RUN_CMD ln $VERBOSE_ARG -sf "${fontPath}" "${fontTarget}"
          '';
        }
      else
        {
          unlinkFont = ''
            if [ -e "${fontTarget}" ] && [ -L "${fontTarget}" ]; then
              $DRY_RUN_CMD rm $VERBOSE_ARG "${fontTarget}"
              if [ -e "${fontBackup}" ]; then
                $DRY_RUN_CMD mv $VERBOSE_ARG "${fontBackup}" "${fontTarget}"
                $DRY_RUN_CMD echo "${fontTarget} has been restored from backup"
              else
                if $DRY_RUN_CMD rm $VERBOSE_ARG -d "${configDir}" 2>/dev/null
                then
                  $DRY_RUN_CMD echo "removed empty ${configDir}"
                fi
              fi
            fi
          '';
        };
  };
}
