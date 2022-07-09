# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

{ pkgs ? (import ../lib/nixpkgs-pinned.nix { }) }:

import ../pkgs/proot-termux {
  inherit pkgs;
  cross = false;
  static = false;
}
