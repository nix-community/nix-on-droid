{
  description = "nix-on-droid configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-22.05";
    nix-on-droid.url = "<<FLAKE_URL>>";
    nix-on-droid.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nix-on-droid, ... }: {
    nixOnDroidConfigurations = {
      default = nix-on-droid.lib.nixOnDroidConfiguration {
        modules = [ ./nix-on-droid.nix ];
      };
    };
  };
}
