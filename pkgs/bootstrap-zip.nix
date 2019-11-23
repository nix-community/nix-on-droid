# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ config, runCommand, zip, bootstrap }:

runCommand "bootstrap-zip" { } ''
  mkdir $out
  cd ${bootstrap}
  ${zip}/bin/zip -q -9 -r $out/bootstrap-${config.build.arch} ./* ./.l2s
''
