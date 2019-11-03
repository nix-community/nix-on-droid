# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ config, writeTextDir }:

writeTextDir "etc/group" ''
  root:x:0:
  ${config.user.group}:x:${config.user.gid}:${config.user.user}
''
