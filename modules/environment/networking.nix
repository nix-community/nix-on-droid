# Copyright (c) 2019-2023, see AUTHORS. Licensed under MIT License, see LICENSE.

# Inspired by
# https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/config/networking.nix
# (Copyright (c) 2003-2023 Eelco Dolstra and the Nixpkgs/NixOS contributors,
#  licensed under MIT License as well)

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.networking;

  localhostMultiple = any (elem "localhost") (attrValues (removeAttrs cfg.hosts [ "127.0.0.1" "::1" ]));
in

{

  ###### interface

  options = {

    networking.hosts = lib.mkOption {
      type = types.attrsOf (types.listOf types.str);
      default = { };
      example = literalExpression ''
        {
          "127.0.0.1" = [ "foo.bar.baz" ];
          "192.168.0.2" = [ "fileserver.local" "nameserver.local" ];
        };
      '';
      description = lib.mdDoc ''
        Locally defined maps of hostnames to IP addresses.
      '';
    };

    networking.hostFiles = lib.mkOption {
      type = types.listOf types.path;
      defaultText = literalMD "Hosts from {option}`networking.hosts` and {option}`networking.extraHosts`";
      example = literalExpression ''[ "''${pkgs.my-blocklist-package}/share/my-blocklist/hosts" ]'';
      description = lib.mdDoc ''
        Files that should be concatenated together to form {file}`/etc/hosts`.
      '';
    };

    networking.extraHosts = lib.mkOption {
      type = types.lines;
      default = "";
      example = "192.168.0.1 lanlocalhost";
      description = lib.mdDoc ''
        Additional verbatim entries to be appended to {file}`/etc/hosts`.
        For adding hosts from derivation results, use {option}`networking.hostFiles` instead.
      '';
    };

  };


  ###### implementation

  config = {

    assertions = [{
      assertion = !localhostMultiple;
      message = ''
        `networking.hosts` maps "localhost" to something other than "127.0.0.1"
        or "::1". This will break some applications. Please use
        `networking.extraHosts` if you really want to add such a mapping.
      '';
    }];

    networking.hostFiles =
      let
        localhostHosts = pkgs.writeText "localhost-hosts" ''
          127.0.0.1 localhost
          ::1 localhost
        '';
        stringHosts =
          let
            oneToString = set: ip: ip + " " + concatStringsSep " " set.${ip} + "\n";
            allToString = set: concatMapStrings (oneToString set) (attrNames set);
          in
          pkgs.writeText "string-hosts" (allToString (filterAttrs (_: v: v != [ ]) cfg.hosts));
        extraHosts = pkgs.writeText "extra-hosts" cfg.extraHosts;
      in
      mkBefore [ localhostHosts stringHosts extraHosts ];

    environment.etc = {
      # /etc/services: TCP/UDP port assignments.
      services.source = pkgs.iana-etc + "/etc/services";

      # /etc/protocols: IP protocol numbers.
      protocols.source = pkgs.iana-etc + "/etc/protocols";

      # /etc/hosts: Hostname-to-IP mappings.
      hosts.source = pkgs.concatText "hosts" cfg.hostFiles;

      "resolv.conf".text = ''
        nameserver 1.1.1.1
        nameserver 8.8.8.8
      '';
    };

  };

}
