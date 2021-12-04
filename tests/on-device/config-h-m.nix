{ pkgs, config, ... }:

{
  system.stateVersion = "21.11";

  home-manager.config =
    { pkgs, lib, ... }:
    {
      home.stateVersion = "21.11";
      nixpkgs = { inherit (config.nixpkgs) overlays; };

      # example config
      xdg.configFile.example.text = "example config";

      # example package
      home.packages = [ pkgs.dash ];
    };
}
