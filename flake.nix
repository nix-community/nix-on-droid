{
  description = "Nix-enabled environment for your Android device";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";

    # for bootstrap zip ball creation and proot-termux builds, we use a fixed version of nixpkgs to ease maintanence.
    # head of nixos-22.11 as of 2023-01-05
    # note: when updating nixpkgs-for-bootstrap, update store paths of proot-termux in modules/environment/login/default.nix
    nixpkgs-for-bootstrap.url = "github:NixOS/nixpkgs/37d8b66e6acc039dd5d5504aa1fdf0f2847444c5";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-formatter-pack = {
      url = "github:Gerschtli/nix-formatter-pack";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nmd = {
      url = "gitlab:rycee/nmd";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nixpkgs-for-bootstrap, home-manager, nix-formatter-pack, nmd }:
    let
      forEachSystem = nixpkgs.lib.genAttrs [ "aarch64-linux" "x86_64-linux" ];

      overlay = nixpkgs.lib.composeManyExtensions (import ./overlays);

      pkgs' = import nixpkgs {
        system = "aarch64-linux";
        overlays = [ overlay ];
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
      apps = forEachSystem (system: {
        default = self.apps.${system}.nix-on-droid;

        nix-on-droid = {
          type = "app";
          program = "${self.packages.${system}.nix-on-droid}/bin/nix-on-droid";
        };

        deploy = {
          type = "app";
          program = toString (import ./scripts/deploy.nix { inherit nixpkgs system; });
        };

        fakedroid = {
          type = "app";
          program = toString self.packages.${system}.fakedroid;
        };
      });

      checks = forEachSystem (system: {
        nix-formatter-pack-check = nix-formatter-pack.lib.mkCheck formatterPackArgsFor.${system};
      });

      formatter = forEachSystem (system: nix-formatter-pack.lib.mkFormatter formatterPackArgsFor.${system});

      lib.nixOnDroidConfiguration =
        { modules ? [ ]
        , extraSpecialArgs ? { }
        , pkgs ? pkgs'
        , home-manager-path ? home-manager.outPath
          # deprecated:
        , config ? null
        , extraModules ? null
        , system ? null
        }:
        if pkgs.system != "aarch64-linux" then
          throw "aarch64-linux is the only currently supported system type"
        else
          pkgs.lib.throwIf
            (config != null || extraModules != null)
            ''
              The 'nixOnDroidConfiguration' arguments

              - 'config'
              - 'extraModules'
              - 'system'

              have been removed. Instead use the argument 'modules'. The
              'system' will be inferred by 'pkgs.system'.
              See the 22.11 release notes for more.
            ''
            (import ./modules {
              inherit extraSpecialArgs home-manager-path pkgs;
              config.imports = modules;
              isFlake = true;
            });

      overlays.default = overlay;

      packages = forEachSystem (system:
        let
          nixOnDroidPkgs = import ./pkgs {
            inherit system;
            nixpkgs = nixpkgs-for-bootstrap;
          };

          docs = import ./docs {
            inherit home-manager;
            pkgs = nixpkgs.legacyPackages.${system};
            nmdSrc = nmd;
          };
        in
        {
          fakedroid = import ./tests {
            inherit system;
            nixpkgs = nixpkgs-for-bootstrap;
          };

          nix-on-droid = nixpkgs.legacyPackages.${system}.callPackage ./nix-on-droid { };
        }
        // nixOnDroidPkgs.customPkgs
        // docs
      );

      templates = {
        default = self.templates.minimal;

        minimal = {
          path = ./templates/minimal;
          description = "Minimal example of Nix-on-Droid system config.";
        };

        home-manager = {
          path = ./templates/home-manager;
          description = "Minimal example of Nix-on-Droid system config with home-manager.";
        };

        advanced = {
          path = ./templates/advanced;
          description = "Advanced example of Nix-on-Droid system config with home-manager.";
        };
      };
    };
}
