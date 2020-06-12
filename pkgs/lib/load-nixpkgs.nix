# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

let
  defaultNixpkgsArgs = {
    config = { };
    overlays = [
      (self: super: {
        gdb = super.gdb.override {
          # actual default value of safePaths, but `lib` does not exist when cross-compiling:
          # [
          #   # $debugdir:$datadir/auto-load are whitelisted by default by GDB
          #   "$debugdir" "$datadir/auto-load"
          #   # targetPackages so we get the right libc when cross-compiling and using buildPackages.gdb
          #   targetPackages.stdenv.cc.cc.lib
          # ]
          safePaths = [ "$debugdir" "$datadir/auto-load" ];
        };
      })
    ];
  };

  # head of nixos-20.03 as of 2020-06-11
  # note: when updating nixpkgs, update store paths of proot-termux in modules/environment/login/default.nix
  pinnedPkgsSrc = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/8b071be7512bd2cd0ff5c3bdf60f01ab4eb94abd.tar.gz";
    sha256 = "079rzd17y2pk48kh70pbp4a7mh56vi2b49lzd365ckh38gdv702z";
  };
in

args: import pinnedPkgsSrc (args // defaultNixpkgsArgs)
