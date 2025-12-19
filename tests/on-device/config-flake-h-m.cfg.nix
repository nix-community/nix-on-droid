{ pkgs, config, ... }:

{
  system.stateVersion = "25.11";

  # no nixpkgs.overlays defined
  environment.packages = with pkgs; [ zsh ];

  home-manager.config =
    { pkgs, ... }:
    {
      home.stateVersion = "25.11";

      nixpkgs.overlays = config.nixpkgs.overlays;
      home.packages = with pkgs; [ dash ];
    };
  nixpkgs.overlays = [ ];
}
