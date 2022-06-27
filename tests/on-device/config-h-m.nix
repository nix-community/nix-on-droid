{ pkgs, config, ... }:

{
  system.stateVersion = "22.05";

  home-manager.config =
    { pkgs, lib, ... }:
    {
      home.stateVersion = "22.05";
      nixpkgs = { inherit (config.nixpkgs) overlays; };

      # example config
      xdg.configFile.example.text = "example config";

      # example package
      home.packages = [ pkgs.dash ];
    };
}
