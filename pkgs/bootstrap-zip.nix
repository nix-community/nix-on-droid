# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ lib, runCommand, gnutar, bootstrap, targetSystem }:

let
  arch = lib.strings.removeSuffix "-linux" targetSystem;
in
runCommand "bootstrap-zip" { } ''
  mkdir $out
  cd ${bootstrap}
  ${gnutar}/bin/tar czf $out/bootstrap-${arch}.tar.gz ./* ./.l2s
''
