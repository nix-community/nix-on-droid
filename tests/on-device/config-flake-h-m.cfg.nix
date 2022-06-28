{ pkgs, config, ... }:

{
  system.stateVersion = "22.05";

  # no nixpkgs.overlays defined
  environment.packages = with pkgs; [ zsh ];

  home-manager.config =
    { pkgs, ... }:
    {
      home.stateVersion = "22.05";

      nixpkgs.overlays = config.nixpkgs.overlays;
      home.packages = with pkgs; [ dash ];
    };
  nixpkgs.overlays = [];
}
