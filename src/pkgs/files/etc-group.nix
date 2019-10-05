# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ writeTextDir, userName, groupName, ids }:

writeTextDir "etc/group" ''
  root:x:0:
  ${groupName}:x:${(import ids).gid}:${userName}
''
