{
  description = "Nix-enabled environment for your Android device";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";

    # for bootstrap zip ball creation and proot-termux builds, we use a fixed version of nixpkgs to ease maintanence.
    # head of nixos-23.11 as of 2024-02-17
    # note: when updating nixpkgs-for-bootstrap, update store paths of proot-termux in modules/environment/login/default.nix
    nixpkgs-for-bootstrap.url = "github:NixOS/nixpkgs/1d1817869c47682a6bee85b5b0a6537b6c0fba26";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-formatter-pack = {
      url = "github:Gerschtli/nix-formatter-pack";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-docs.url = "github:NixOS/nixpkgs/release-23.11";

    nmd = {
      url = "sourcehut:~rycee/nmd";
      inputs.nixpkgs.follows = "nixpkgs-docs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-for-bootstrap, home-manager, nix-formatter-pack, nmd, nixpkgs-docs }:
    let
      forEachSystem = nixpkgs.lib.genAttrs [ "aarch64-linux" "x86_64-linux" ];

      overlay = nixpkgs.lib.composeManyExtensions (import ./overlays);

      pkgsPerSystem = system: import nixpkgs {
        inherit system;
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
      });

      checks = forEachSystem (system: {
        nix-formatter-pack-check = nix-formatter-pack.lib.mkCheck formatterPackArgsFor.${system};
      });

      formatter = forEachSystem (system: nix-formatter-pack.lib.mkFormatter formatterPackArgsFor.${system});

      lib.nixOnDroidConfiguration =
        { modules ? [ ]
        , system ? "aarch64-linux"
        , extraSpecialArgs ? { }
        , pkgs ? pkgsPerSystem system
        , home-manager-path ? home-manager.outPath
          # deprecated:
        , config ? null
        , extraModules ? null
        }:
        if ! (builtins.elem system [ "aarch64-linux" "x86_64-linux" ]) then
          throw
            ("${system} is not supported; aarch64-linux / x86_64-linux " +
              "are the only currently supported system types")
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
              config.build.arch =
                nixpkgs.lib.strings.removeSuffix "-linux" system;
              isFlake = true;
            });

      overlays.default = overlay;

      packages = forEachSystem (system:
        let
          flattenArch = arch: derivationAttrset:
            nixpkgs.lib.attrsets.mapAttrs'
              (name: drv:
                nixpkgs.lib.attrsets.nameValuePair (name + "-" + arch) drv
              )
              derivationAttrset;
          perArchCustomPkgs = arch: flattenArch arch
            (import ./pkgs {
              inherit system arch;
              nixpkgs = nixpkgs-for-bootstrap;
            }).customPkgs;

          docs = import ./docs {
            inherit home-manager;
            pkgs = nixpkgs-docs.legacyPackages.${system};
            nmdSrc = nmd;
          };
        in
        {
          nix-on-droid = nixpkgs.legacyPackages.${system}.callPackage ./nix-on-droid { };
        }
        // (perArchCustomPkgs "aarch64")
        // (perArchCustomPkgs "x86_64")
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
