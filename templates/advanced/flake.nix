{
  description = "Advanced example of nix-on-droid system config with home-manager.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-22.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-on-droid = {
      url = "github:t184256/nix-on-droid/release-22.05";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-on-droid }: {

    nixOnDroidConfigurations.deviceName = nix-on-droid.lib.nixOnDroidConfiguration {
      system = "aarch64-linux";
      config = ./nix-on-droid.nix;

      # list of extra modules for nix-on-droid system
      extraModules = [
        # { nix.registry.nixpkgs.flake = nixpkgs; }
        # ./path/to/module.nix

        # or import source out-of-tree modules like:
        # flake.nixOnDroidModules.module
      ];

      # list of extra special args for nix-on-droid modules
      extraSpecialArgs = {
        # rootPath = ./.;
      };

      # set nixpkgs instance, it is recommended to apply nix-on-droid.overlays.default
      pkgs = import nixpkgs {
        system = "aarch64-linux";

        overlays = [
          nix-on-droid.overlays.default
          # add other overlays
        ];
      };

      # set path to home-manager flake
      home-manager-path = home-manager.outPath;
    };

  };
}
