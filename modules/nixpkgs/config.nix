# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

# Inspired by
# https://github.com/rycee/home-manager/blob/master/modules/misc/nixpkgs.nix
# (Copyright (c) 2017-2019 Robert Helgesson and Home Manager contributors,
#  licensed under MIT License as well)

{ config, lib, pkgs, ... }:

with lib;

{
  ###### implementation

  config = {

    _module.args.pkgs = import <nixpkgs> (
      filterAttrs (_n: v: v != null) config.nixpkgs
    );

    nixpkgs.overlays = import ../../overlays;

  };
}
