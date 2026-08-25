{ pkgs, ... }:

{
  system.stateVersion = "24.11";

  networking = {
    hosts."127.0.0.2" = [ "a" "b" ];

    extraHosts = ''
      127.0.0.3 c
    '';

    hostFiles = [
      (pkgs.writeText "hosts" ''
        127.0.0.4 d
      '')
    ];
  };
}
