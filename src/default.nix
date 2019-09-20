{ arch }:

assert builtins.elem arch [ "aarch64" "i686" ];

let
  nixpkgs = import <nixpkgs> { };

  pinnedPkgs = import ./pinned-pkgs.nix {
    inherit arch;
    inherit (nixpkgs) fetchFromGitHub;
  };
in

import ./pkgs {
  inherit arch;
  inherit (pinnedPkgs) buildPkgs crossPkgs crossStaticPkgs;
}
