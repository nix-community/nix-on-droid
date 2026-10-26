{ pkgs, ... }:

{
  system.stateVersion = "24.11";

  networking.hosts."127.0.0.2" = [ "localhost" ];
}
