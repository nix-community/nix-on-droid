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

  # head of nixos-20.09 as of 2020-11-07
  # note: when updating nixpkgs, update store paths of proot-termux in modules/environment/login/default.nix
  pinnedPkgsSrc = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/d105075a1fd870b1d1617a6008cb38b443e65433.tar.gz";
    sha256 = "1jcs44wn0s6mlf2jps25bvcai1rij9b2dil6zcj8zqwf2i8xmqjh";
  };
in

args: import pinnedPkgsSrc (args // defaultNixpkgsArgs)
