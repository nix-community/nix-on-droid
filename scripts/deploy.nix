# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

{ nixpkgs, system }:

let
  pkgs = nixpkgs.legacyPackages.${system};

  runtimePackages = with pkgs; [
    coreutils
    diffutils
    git
    gnugrep
    gnused
    gnutar
    gzip
    jq
    nix
    openssh
    rsync
  ];
in

pkgs.runCommand
  "deploy"
{
  preferLocalBuild = true;
  allowSubstitutes = false;
}
  ''
    install -D -m755  ${./deploy.sh} $out

    substituteInPlace $out \
      --subst-var-by bash "${pkgs.bash}" \
      --subst-var-by path "${pkgs.lib.makeBinPath runtimePackages}"
  ''
