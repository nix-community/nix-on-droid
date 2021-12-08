{
  description = "Nix-enabled environment for your Android device";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, flake-utils }: let
    supportedSystems = [ "aarch64-linux" "i686-linux" ];
  in flake-utils.lib.eachSystem supportedSystems (system: let
    defaultPkgs = import nixpkgs {
      inherit system;
      overlays = [ self.overlay ];
    };
    defaultHm = home-manager.outPath;
  in rec {
    lib.nix-on-droid = { pkgs ? defaultPkgs, home-manager-path ? defaultHm, config }: import ./modules {
      inherit pkgs home-manager-path config;
      isFlake = true;
    };

    apps.nix-on-droid = flake-utils.lib.mkApp {
      drv = (defaultPkgs.callPackage ./nix-on-droid { });
    };
    defaultApp = apps.nix-on-droid;
  }) // {
    overlay = nixpkgs.lib.composeManyExtensions (import ./overlays);
  };
}
