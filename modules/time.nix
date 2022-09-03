# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

# Inspired by
# https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/config/locale.nix
# (Copyright (c) 2003-2019 Eelco Dolstra and the Nixpkgs/NixOS contributors,
#  licensed under MIT License as well)

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.time;

  tzdir = "${pkgs.tzdata}/share/zoneinfo";
  nospace = str: filter (c: c == " ") (stringToCharacters str) == [ ];
  timezoneType = types.nullOr (types.addCheck types.str nospace)
    // { description = "null or string without spaces"; };
in

{

  ###### interface

  options = {

    time.timeZone = mkOption {
      default = null;
      type = timezoneType;
      example = "America/New_York";
      description = ''
        The time zone used when displaying times and dates. See <link
        xlink:href="https://en.wikipedia.org/wiki/List_of_tz_database_time_zones"/>
        for a comprehensive list of possible values for this setting.
        If null, the timezone will default to UTC.
      '';
    };

  };


  ###### implementation

  config = {

    environment = {
      etc =
        { zoneinfo.source = tzdir; }
        // optionalAttrs (config.time.timeZone != null) {
          localtime.source = "/etc/zoneinfo/${config.time.timeZone}";
        };

      sessionVariables.TZDIR = "/etc/zoneinfo";
    };

  };
}
