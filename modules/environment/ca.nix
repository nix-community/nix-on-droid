# Copyright (c) 2019-2021, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, lib, pkgs, ... }:

with lib;

let
  certificate = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
in

{

  ###### interface

  options = { };


  ###### implementation

  config = {

    environment.etc = {
      # NixOS canonical location + Debian/Ubuntu/Arch/Gentoo compatibility.
      "ssl/certs/ca-certificates.crt".source = certificate;

      # Old NixOS compatibility.
      "ssl/certs/ca-bundle.crt".source = certificate;

      # CentOS/Fedora compatibility.
      "pki/tls/certs/ca-bundle.crt".source = certificate;
    };

  };

}
