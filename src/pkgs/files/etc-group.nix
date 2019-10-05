# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ coreutils, runCommand, writeTextDir, instDir, userName, groupName }:

let
  ids = runCommand "ids" {} ''
    mkdir $out
    echo -n $(${coreutils}/bin/id -u) > $out/uid
    echo -n $(${coreutils}/bin/id -g) > $out/gid
  '';
  gid = builtins.readFile "${ids}/gid";

in

writeTextDir "etc/group" ''
  root:x:0:
  ${groupName}:x:${gid}:${userName}
''

