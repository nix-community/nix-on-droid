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

      pkgsPerSystem = system: import nixpkgs {
        inherit system;
        overlays = [ overlay ];
      };

      appPerSystem = system: flake-utils.lib.mkApp {
        drv = (pkgsPerSystem system).callPackage ./nix-on-droid { };
      };
    in
    {
      inherit overlay;

      lib.nixOnDroidConfiguration =
        { config
        , system
        , extraModules ? [ ]
        , extraSpecialArgs ? { }
        , pkgs ? pkgsPerSystem system
        , home-manager-path ? home-manager.outPath
        }:
        import ./modules {
          inherit config extraModules extraSpecialArgs home-manager-path pkgs;
          isFlake = true;
        };
    }
    // flake-utils.lib.eachSystem
      [ "aarch64-linux" ]
      (system: {
        apps.nix-on-droid = appPerSystem system;
        defaultApp = appPerSystem system;
      });
}
