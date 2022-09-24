{
  description = "Nix-enabled environment for your Android device";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";

    # for bootstrap zip ball creation and proot-termux builds, we use a fixed version of nixpkgs to ease maintanence.
    # head of nixos-22.05 as of 2022-06-27
    # note: when updating nixpkgs-for-bootstrap, update store paths of proot-termux in modules/environment/login/default.nix
    nixpkgs-for-bootstrap.url = "github:NixOS/nixpkgs/cd90e773eae83ba7733d2377b6cdf84d45558780";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgs-for-bootstrap, home-manager, flake-utils }:
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
    // flake-utils.lib.eachSystem [ "aarch64-linux" "i686-linux" "x86_64-darwin" "x86_64-linux" ] (system: {
      formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;

      packages = import ./pkgs {
        inherit system;
        nixpkgs = nixpkgs-for-bootstrap;
      };
    });
}
