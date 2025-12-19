{ pkgs, config, ... }:

{
  system.stateVersion = "25.11";

  home-manager.config =
    { pkgs, lib, ... }:
    {
      home.stateVersion = "25.11";
      nixpkgs = { inherit (config.nixpkgs) overlays; };

      # example config
      xdg.configFile.example.text = "example config";

      # example package
      home.packages = [ pkgs.dash ];
    };
}
