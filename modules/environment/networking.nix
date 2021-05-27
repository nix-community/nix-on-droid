# Copyright (c) 2019-2021, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, lib, pkgs, ... }:

with lib;

{

  ###### interface

  options = {

  };


  ###### implementation

  config = {

    environment.etc = {
      # /etc/services: TCP/UDP port assignments.
      services.source = pkgs.iana-etc + "/etc/services";

      # /etc/protocols: IP protocol numbers.
      protocols.source = pkgs.iana-etc + "/etc/protocols";

      # /etc/hosts: Hostname-to-IP mappings.
      hosts.text = ''
        127.0.0.1 localhost
        ::1 localhost
      '';
    };

  };

}
