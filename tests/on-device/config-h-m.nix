{ pkgs, config, ... }:

{
  system.stateVersion = "24.05";

  home-manager.config =
    { pkgs, lib, ... }:
    {
      home.stateVersion = "24.05";
      nixpkgs = { inherit (config.nixpkgs) overlays; };

      # example config
      xdg.configFile.example.text = "example config";

      # example package
      home.packages = [ pkgs.dash ];
    };
}
