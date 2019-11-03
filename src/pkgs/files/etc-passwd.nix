# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ config, writeTextDir }:

writeTextDir "etc/passwd" ''
  root:x:0:0:System administrator:${config.core.installation}/root:/bin/sh
  ${config.user.user}:x:${config.user.uid}:${config.user.gid}:${config.user.user}:${config.user.home}:${config.user.shell}
''
