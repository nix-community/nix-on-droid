# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.
{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.terminal;
in
{
  ###### interface

  options = {
    terminal = {
      font = mkOption {
        default = null;
        type = types.nullOr types.path;
        example =
          lib.literalExpression
            ''"''${pkgs.terminus_font_ttf}/share/fonts/truetype/TerminusTTF.ttf"'';
        description = ''
          Font used for the terminal.
        '';
      };
      colors = mkOption {
        default = { };
        type = types.lazyAttrsOf types.str;
        example = lib.literalExpression ''
          {
            background = "#000000";
            foreground = "#FFFFFF";
            cursor = "#FFFFFF";
          }
        '';
        description = ''
          Colorscheme used for the terminal.
        '';
      };
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

        inherit (lib.generators) toKeyValue;

        colors = pkgs.writeTextFile {
          name = "colors.properties";
          text = toKeyValue { } cfg.colors;
        };
        colorsTarget = "${configDir}/colors.properties";
        colorsBackup = "${configDir}/colors.properties.bak";
        colorsPath = "${config.build.installationDir}/${colors}";
      in
      (
        if (cfg.font != null)
        then {
          linkFont = ''
            $DRY_RUN_CMD mkdir $VERBOSE_ARG -p "${configDir}"
            if [ -e "${fontTarget}" ] && ! [ -L "${fontTarget}" ]; then
              $DRY_RUN_CMD mv $VERBOSE_ARG "${fontTarget}" "${fontBackup}"
              $DRY_RUN_CMD echo "${fontTarget} has been moved to ${fontBackup}"
            fi
            $DRY_RUN_CMD ln $VERBOSE_ARG -sf "${fontPath}" "${fontTarget}"
          '';
        }
        else {
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
        }
      )
      // (
        if (cfg.colors != { })
        then {
          linkColors = ''
            $DRY_RUN_CMD mkdir $VERBOSE_ARG -p "${configDir}"
            if [ -e "${colorsTarget}" ] && ! [ -L "${colorsTarget}" ]; then
              $DRY_RUN_CMD mv $VERBOSE_ARG "${colorsTarget}" "${colorsBackup}"
              $DRY_RUN_CMD echo "${colorsTarget} has been moved to ${colorsBackup}"
            fi
            $DRY_RUN_CMD ln $VERBOSE_ARG -sf "${colorsPath}" "${colorsTarget}"
          '';
        }
        else {
          unlinkColors = ''
            if [ -e "${colorsTarget}" ] && [ -L "${colorsTarget}" ]; then
              $DRY_RUN_CMD rm $VERBOSE_ARG "${colorsTarget}"
              if [ -e "${colorsBackup}" ]; then
                $DRY_RUN_CMD mv $VERBOSE_ARG "${colorsBackup}" "${colorsTarget}"
                $DRY_RUN_CMD echo "${colorsTarget} has been restored from backup"
              else
                if $DRY_RUN_CMD rm $VERBOSE_ARG -d "${configDir}" 2>/dev/null
                then
                  $DRY_RUN_CMD echo "removed empty ${configDir}"
                fi
              fi
            fi
          '';
        }
      );
  };
}
