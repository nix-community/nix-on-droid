# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

{ nixpkgs, system }:

let
  bootstrap = import ../pkgs {
    inherit nixpkgs system;
    nixOnDroidChannelURL = "file:///n-o-d/archive.tar.gz";
  };
in

nixpkgs.legacyPackages.${system}.runCommand
  "fakedroid"
{
  preferLocalBuild = true;
  allowSubstitutes = false;
}
  ''
    install -D -m755  ${./fakedroid.sh} $out

    substituteInPlace $out \
      --subst-var-by bootstrapZip "${bootstrap.customPkgs.bootstrapZip}" \
      --subst-var-by prootTest "${bootstrap.customPkgs.prootTermuxTest}" \
      --subst-var-by installationDir "${bootstrap.config.build.installationDir}" \
      --subst-var-by homeDir "${bootstrap.config.user.home}" \
  ''
