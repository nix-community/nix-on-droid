{
  description = "nix-on-droid configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-22.05";
    home-manager.url = "github:nix-community/home-manager/release-22.05";
    nix-on-droid.url = "<<FLAKE_URL>>";
    nix-on-droid.inputs.nixpkgs.follows = "nixpkgs";
    nix-on-droid.inputs.home-manager.follows = "home-manager";
  };

  outputs = { nix-on-droid, ... }: {
    nixOnDroidConfigurations = {
      device = nix-on-droid.lib.nixOnDroidConfiguration {
        config = ./nix-on-droid.nix;
        system = "aarch64-linux";
      };
    };
  };
}
