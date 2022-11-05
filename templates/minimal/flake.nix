{
  description = "Basic example of nix-on-droid system config.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";

    nix-on-droid = {
      url = "github:t184256/nix-on-droid/release-22.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-on-droid }: {

    nixOnDroidConfigurations.deviceName = nix-on-droid.lib.nixOnDroidConfiguration {
      modules = [ ./nix-on-droid.nix ];
    };

  };
}
