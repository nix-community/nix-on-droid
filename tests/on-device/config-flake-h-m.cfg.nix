{ pkgs, config, ... }:

{
  system.stateVersion = "24.11";

  # no nixpkgs.overlays defined
  environment.packages = with pkgs; [ zsh ];

  home-manager.config =
    { pkgs, ... }:
    {
      home.stateVersion = "24.11";

      nixpkgs.overlays = config.nixpkgs.overlays;
      home.packages = with pkgs; [ dash ];
    };
  nixpkgs.overlays = [ ];
}
