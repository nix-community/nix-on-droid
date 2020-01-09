# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

{ config, runCommand, zip, bootstrap }:

runCommand "bootstrap-zip" { } ''
  mkdir $out
  cd ${bootstrap}
  ${zip}/bin/zip -q -9 -r $out/bootstrap-${config.build.arch} ./* ./.l2s
''
