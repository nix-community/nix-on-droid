# Copyright (c) 2019-2023, see AUTHORS. Licensed under MIT License, see LICENSE.

{ pkgs, nixpkgs, home-manager, nmdSrc }:

let
  nmd = import nmdSrc { inherit pkgs; };

  # Make sure the used package is scrubbed to avoid actually instantiating
  # derivations.
  setupModule = {
    _module.args.pkgs = pkgs.lib.mkForce (nmd.scrubDerivations "pkgs" pkgs);

    system.stateVersion = "19.09";
  };

  modules = import ../modules/module-list.nix {
    inherit pkgs nixpkgs;
    home-manager-path = home-manager.outPath;
    isFlake = true;
  };

  modulesDocs = nmd.buildModulesDocs {
    modules = modules ++ [ setupModule ];
    moduleRootPaths = [ ../. ];
    mkModuleUrl = path: "https://github.com/nix-community/nix-on-droid/blob/master/${path}";
    channelName = "nix-on-droid";
    docBook.id = "nix-on-droid-options";
  };

  docs = nmd.buildDocBookDocs {
    pathName = "nix-on-droid";
    modulesDocs = [ modulesDocs ];
    documentsDirectory = ./.;
    chunkToc = ''
      <toc>
        <d:tocentry xmlns:d="http://docbook.org/ns/docbook" linkend="book-manual"><?dbhtml filename="index.html"?>
          <d:tocentry linkend="ch-options"><?dbhtml filename="nix-on-droid-options.html"?></d:tocentry>
        </d:tocentry>
      </toc>
    '';
  };
in

{
  inherit (docs) manPages;

  optionsJson = pkgs.symlinkJoin {
    name = "nix-on-droid-options-json";
    paths = [
      (modulesDocs.json.override {
        path = "share/doc/nix-on-droid/nix-on-droid-options.json";
      })
    ];
  };

  manualHtml = docs.html;
}
