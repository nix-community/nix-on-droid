# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ callPackage }:

let
  ids = import (callPackage ./ids.nix { });

  userName = "nix-on-droid";
in

{
  buildConfig = { arch, initialBuild, nixOnDroidChannelURL }: (
    {
      channel = {
        nix-on-droid = nixOnDroidChannelURL;
        nixpkgs = "https://nixos.org/channels/nixos-19.09";
      };

      core = {
        inherit arch initialBuild;

        installation = "/data/data/com.termux.nix/files/usr";
      };

      user = {
        inherit (ids) gid uid;

        group = userName;
        home = "/data/data/com.termux.nix/files/home";
        shell = "/bin/sh";
        user = userName;
      };
    }
  );

  loadNixpkgs = callPackage ./load-nixpkgs.nix { };

  writeTextDir = callPackage ./write-text-dir.nix { };
}
