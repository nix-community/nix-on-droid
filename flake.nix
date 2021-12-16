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
      inherit overlay;

      lib.nixOnDroidConfiguration =
        { config
        , system ? "aarch64-linux"  # unused
        , extraModules ? [ ]
        , extraSpecialArgs ? { }
        , pkgs ? pkgs'
        , home-manager-path ? home-manager.outPath
        }:
        import ./modules {
          inherit config extraModules extraSpecialArgs home-manager-path pkgs;
          isFlake = true;
        };
      apps.nix-on-droid.aarch64-linux = app;
      defaultApp.aarch64-linux = app;
    };
}
