# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ writeTextFile }:

# TODO: remove when https://github.com/NixOS/nixpkgs/pull/64421 got merged into stable
path: text: writeTextFile {
  inherit text;
  name = builtins.baseNameOf path;
  destination = "/${path}";
}
