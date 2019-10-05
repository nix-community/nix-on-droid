# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ coreutils, runCommand, writeTextDir, instDir, userName, shell }:

let
  ids = runCommand "ids" {} ''
    mkdir $out
    echo -n $(${coreutils}/bin/id -u) > $out/uid
    echo -n $(${coreutils}/bin/id -g) > $out/gid
  '';
  uid = builtins.readFile "${ids}/uid";
  gid = builtins.readFile "${ids}/gid";
in

writeTextDir "etc/passwd" ''
  root:x:0:0:System administrator:${instDir}/root:/bin/sh
  ${userName}:x:${uid}:${gid}:/data/data/com.termux.nix/files/home:${shell}
''
