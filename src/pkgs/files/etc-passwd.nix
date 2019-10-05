# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ writeTextDir, instDir, userName, shell, ids }:

let
  idSet = import ids;
in

writeTextDir "etc/passwd" ''
  root:x:0:0:System administrator:${instDir}/root:/bin/sh
  ${userName}:x:${idSet.uid}:${idSet.gid}:/data/data/com.termux.nix/files/home:${shell}
''
