{ pkgs, ... }:

{
  system.stateVersion = "23.11";

  networking.hosts."127.0.0.2" = [ "localhost" ];
}
