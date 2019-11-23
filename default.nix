{ pkgs ? import <nixpkgs> { } }:

{
  nix-on-droid = pkgs.callPackage ./nix-on-droid { };
}
