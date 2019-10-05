# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ buildPkgs }:

buildPkgs.runCommand "ids.nix" {} ''
  cat > $out <<EOF
  {
    gid = "$(${buildPkgs.coreutils}/bin/id -g)";
    uid = "$(${buildPkgs.coreutils}/bin/id -u)";
  }
  EOF
''
