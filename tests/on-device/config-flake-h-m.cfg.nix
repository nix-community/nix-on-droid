{ pkgs, config, ... }:

{
  system.stateVersion = "24.05";

  # no nixpkgs.overlays defined
  environment.packages = with pkgs; [ zsh ];

  home-manager.config =
    { pkgs, ... }:
    {
      home.stateVersion = "24.05";

      nixpkgs.overlays = config.nixpkgs.overlays;
      home.packages = with pkgs; [ dash ];
    };
  nixpkgs.overlays = [ ];
}
