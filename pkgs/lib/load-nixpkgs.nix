# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

let
  defaultNixpkgsArgs = {
    config = { };
    overlays = [ ];
  };

  # head of nixos-19.09 as of 2019-11-28
  # note: when updating nixpkgs, update store paths of proot-termux in modules/environment/login/default.nix
  pinnedPkgsSrc = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/73fb59dbb89ed5f754249761dcd99c6ccbd24bb5.tar.gz";
    sha256 = "0fp85c907qw1qnxs40dx4yas9z5fqr9gszk4nazx90hwbimyk6n6";
  };
in

args: import pinnedPkgsSrc (args // defaultNixpkgsArgs)
