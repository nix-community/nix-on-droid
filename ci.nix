with import <nixpkgs> { };

let
  src = import ./src;
in

lib.genAttrs
  [ "aarch64" "i686" ]
  (arch: (src { inherit arch; }) // { recurseForDerivations = true; })
