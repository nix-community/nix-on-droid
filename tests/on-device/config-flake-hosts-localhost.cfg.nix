{ pkgs, ... }:

{
  system.stateVersion = "23.05";

  networking.hosts."127.0.0.2" = [ "localhost" ];
}
