{
  description = "nix-on-droid configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-21.11";
    nix-on-droid.url = "<<FLAKE_URL>>";
    nix-on-droid.inputs.nixpkgs.follows = "nixpkgs";
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
