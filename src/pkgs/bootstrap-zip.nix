{ arch, buildPkgs, bootstrap }:

buildPkgs.runCommand "bootstrap-zip" { } ''
  mkdir $out
  cd ${bootstrap}
  ${buildPkgs.zip}/bin/zip -q -9 -r $out/bootstrap-${arch} ./* ./.l2s
''
