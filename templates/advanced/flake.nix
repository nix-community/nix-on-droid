{
  description = "Advanced example of Nix-on-Droid system config with home-manager.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-on-droid }: {

    nixOnDroidConfigurations.default = nix-on-droid.lib.nixOnDroidConfiguration {
      modules = [
        ./nix-on-droid.nix

        # list of extra modules for Nix-on-Droid system
        # { nix.registry.nixpkgs.flake = nixpkgs; }
        # ./path/to/module.nix

        # or import source out-of-tree modules like:
        # flake.nixOnDroidModules.module
      ];

      # list of extra special args for Nix-on-Droid modules
      extraSpecialArgs = {
        # rootPath = ./.;
      };

      # set nixpkgs instance, it is recommended to apply `nix-on-droid.overlays.default`
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
