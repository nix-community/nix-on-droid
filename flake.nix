{
  description = "Nix-enabled environment for your Android device";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, flake-utils }:
    {
      overlays = import ./overlays;
    } //
    flake-utils.lib.eachSystem [
      "aarch64-linux"
      "i686-linux"
    ]
      (system:
        let pkgs = import nixpkgs {
          inherit system;
          overlays = self.overlays;
        }; in
        rec {
          lib = {
            nix-on-droid = { config }: import ./modules {
              inherit pkgs config;
              isFlake = true;
              home-manager = (import home-manager { });
            };
          };

          apps.nix-on-droid = flake-utils.lib.mkApp {
            drv = (pkgs.callPackage ./nix-on-droid { });
          };
          defaultApp = apps.nix-on-droid;
        }
      );
}
