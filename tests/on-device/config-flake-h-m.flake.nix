{
  description = "Nix-on-Droid configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-23.11";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    nix-on-droid = {
      url = "<<FLAKE_URL>>";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { nix-on-droid, ... }: {
    nixOnDroidConfigurations = {
      device = nix-on-droid.lib.nixOnDroidConfiguration {
        system = "<<SYSTEM>>";
        modules = [ ./nix-on-droid.nix ];
      };
    };
  };
}
