# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

with import <nixpkgs> { };

with lib;

let
  src = import ./src;

  attrs = genAttrs
    [ "aarch64" "i686" ]
    (arch: (src { inherit arch; }) // { recurseForDerivations = true; });

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

  cachePkgs = filter isCacheable (flattenPkgs attrs);

  outputsOf = p: map (o: p.${o}) p.outputs;
in

concatMap outputsOf cachePkgs
