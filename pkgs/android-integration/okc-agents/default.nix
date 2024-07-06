# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ nixpkgs, pkgs, termux-am }:

let
  okc-agents-unwrapped =
    (import ./Cargo.nix { inherit nixpkgs pkgs; }).rootCrate.build;
in
pkgs.stdenvNoCC.mkDerivation {
  inherit (okc-agents-unwrapped) name version;
  phases = [ "installPhase" ];
  nativeBuildInputs = [ pkgs.makeWrapper ];
  outputs = [ "out" "okc_gpg" ];
  installPhase = ''
    mkdir -p $out/bin $okc_gpg/bin
    makeWrapper ${okc-agents-unwrapped}/bin/okc-gpg \
      $okc_gpg/bin/okc-gpg \
      --prefix PATH : ${pkgs.lib.makeBinPath [ termux-am ]}
    makeWrapper ${okc-agents-unwrapped}/bin/okc-ssh-agent \
      $out/bin/okc-ssh-agent \
      --prefix PATH : ${pkgs.lib.makeBinPath [ termux-am ]}
  '';
}
