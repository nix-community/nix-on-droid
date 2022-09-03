{
  description = "Nix-enabled environment for your Android device";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, home-manager }:
    let
      overlay = nixpkgs.lib.composeManyExtensions (import ./overlays);

      pkgs' = import nixpkgs {
        system = "aarch64-linux";
        overlays = [ overlay ];
      };

      app = flake-utils.lib.mkApp {
        drv = pkgs'.callPackage ./nix-on-droid { };
      };
    in
    {
      overlays.default = overlay;

      lib.nixOnDroidConfiguration =
        { config
        , system ? "aarch64-linux"  # unused, only supported variant
        , extraModules ? [ ]
        , extraSpecialArgs ? { }
        , pkgs ? pkgs'
        , home-manager-path ? home-manager.outPath
        }:
        if system != "aarch64-linux" then
          throw "aarch64-linux is the only currently supported system type"
        else
          import ./modules {
            inherit config extraModules extraSpecialArgs home-manager-path pkgs;
            isFlake = true;
          };

      apps.aarch64-linux = {
        default = app;
        nix-on-droid = app;
      };
    }
    // flake-utils.lib.eachDefaultSystem (system: {
      formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
    });
}
