# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ coreutils, runCommand }:

runCommand "ids.nix" {} ''
  cat > $out <<EOF
  {
    gid = "$(${coreutils}/bin/id -g)";
    uid = "$(${coreutils}/bin/id -u)";
  }
  EOF
''
