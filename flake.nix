{
  description = "Nix-enabled environment for your Android device";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";

    # for bootstrap zip ball creation and proot-termux builds, we use a fixed version of nixpkgs to ease maintanence.
    # head of nixos-24.05 as of 2024-07-06
    # note: when updating nixpkgs-for-bootstrap, update store paths of proot-termux in modules/environment/login/default.nix
    nixpkgs-for-bootstrap.url = "github:NixOS/nixpkgs/49ee0e94463abada1de470c9c07bfc12b36dcf40";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-formatter-pack = {
      url = "github:Gerschtli/nix-formatter-pack";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nmd.follows = "nmd";
    };

    nixpkgs-docs.url = "github:NixOS/nixpkgs/release-23.05";

    nmd = {
      url = "sourcehut:~rycee/nmd";
      inputs.nixpkgs.follows = "nixpkgs-docs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-for-bootstrap, home-manager, nix-formatter-pack, nmd, nixpkgs-docs }:
    let
      forEachSystem = nixpkgs.lib.genAttrs [ "aarch64-linux" "x86_64-linux" ];

      overlay = nixpkgs.lib.composeManyExtensions (import ./overlays);

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
          program = import ./scripts/deploy.nix { inherit nixpkgs system; };
        };
      });

      checks = forEachSystem (system: {
        nix-formatter-pack-check = nix-formatter-pack.lib.mkCheck formatterPackArgsFor.${system};
      });

      formatter = forEachSystem (system: nix-formatter-pack.lib.mkFormatter formatterPackArgsFor.${system});

      lib.nixOnDroidConfiguration =
        { pkgs
        , modules ? [ ]
        , extraSpecialArgs ? { }
        , home-manager-path ? home-manager.outPath
          # deprecated:
        , config ? null
        , extraModules ? null
        , system ? null  # pkgs.system is used to detect user's arch
        }:
        if ! (builtins.elem pkgs.system [ "aarch64-linux" "x86_64-linux" ]) then
          throw
            ("${pkgs.system} is not supported; aarch64-linux / x86_64-linux " +
              "are the only currently supported system types")
        else
          pkgs.lib.throwIf
            (config != null || extraModules != null || system != null)
            ''
              The 'nixOnDroidConfiguration' arguments

              - 'config'
              - 'extraModules'
              - 'system'

              have been removed.
              Instead of 'extraModules' use the argument 'modules'.
              The 'system' will be inferred by 'pkgs.system',
              so pass a 'pkgs = import nixpkgs { system = "aarch64-linux"; };'
              See the 22.11 release notes for more.
            ''
            (import ./modules {
              targetSystem = pkgs.system; # system to cross-compile to
              inherit extraSpecialArgs home-manager-path pkgs;
              config.imports = modules;
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
              _nativeSystem = system; # system to cross-compile from
              system = "${arch}-linux"; # system to cross-compile to
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
