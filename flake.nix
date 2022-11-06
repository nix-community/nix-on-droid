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

    nix-formatter-pack = {
      url = "github:Gerschtli/nix-formatter-pack";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-for-bootstrap, home-manager, nix-formatter-pack }:
    let
      forEachSystem = nixpkgs.lib.genAttrs [ "aarch64-linux" "x86_64-linux" ];

      overlay = nixpkgs.lib.composeManyExtensions (import ./overlays);

      pkgs' = import nixpkgs {
        system = "aarch64-linux";
        overlays = [ overlay ];
      };

      app = {
        type = "app";
        program = "${pkgs'.callPackage ./nix-on-droid { }}/bin/nix-on-droid";
      };

      formatterPackArgsFor = forEachSystem (system: {
        inherit nixpkgs system;
        checkFiles = [ ./. ];

        config.tools = {
          deadnix = {
            enable = true;
            noLambdaPatternNames = true;
          };
          nixpkgs-fmt.enable = true;
          statix.enable = true;
        };
      });
    in
    {
      apps.aarch64-linux = {
        default = app;
        nix-on-droid = app;
      };

      checks = forEachSystem (system: {
        nix-formatter-pack-check = nix-formatter-pack.lib.mkCheck formatterPackArgsFor.${system};
      });

      formatter = forEachSystem (system: nix-formatter-pack.lib.mkFormatter formatterPackArgsFor.${system});

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

      overlays.default = overlay;

      packages = forEachSystem (system:
        (import ./pkgs {
          inherit system;
          nixpkgs = nixpkgs-for-bootstrap;
        }).customPkgs
        // {
          fakedroid = import ./tests {
            inherit system;
            nixpkgs = nixpkgs-for-bootstrap;
          };

          nix-on-droid = nixpkgs.legacyPackages.${system}.callPackage ./nix-on-droid { };
        }
      );

      templates = {
        default = self.templates.minimal;

        minimal = {
          path = ./templates/minimal;
          description = "Minimal example of nix-on-droid system config.";
        };

        home-manager = {
          path = ./templates/home-manager;
          description = "Minimal example of nix-on-droid system config with home-manager.";
        };

        advanced = {
          path = ./templates/advanced;
          description = "Advanced example of nix-on-droid system config with home-manager.";
        };
      };
    };
}
