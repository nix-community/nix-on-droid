# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

with import <nixpkgs> { };

with lib;

let
  pkgs = (import ./pkgs {}) // { recurseForDerivations = true; };
  isCacheable = p: !(p.preferLocalBuild or false);
  shouldRecurseForDerivations = p: isAttrs p && p.recurseForDerivations or false;

  flattenPkgs = s:
    let
      f = p:
        if shouldRecurseForDerivations p then flattenPkgs p
        else if isDerivation p then [ p ]
        else [ ];
    in
      concatMap f (attrValues s);

  cachePkgs = filter isCacheable (flattenPkgs pkgs);

  outputsOf = p: map (o: p.${o}) p.outputs;
in

concatMap outputsOf cachePkgs
