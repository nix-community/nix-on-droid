{ pkgs, config, ... }:

{
  system.stateVersion = "21.11";

  # no nixpkgs.overlays defined
  environment.packages = with pkgs; [ zsh ];

  home-manager.config =
    { pkgs, ... }:
    {
      home.stateVersion = "21.11";

      nixpkgs.overlays = config.nixpkgs.overlays;
      home.packages = with pkgs; [ dash ];
    };
  nixpkgs.overlays = [];
}
