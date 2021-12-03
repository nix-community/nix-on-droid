# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

{ pkgs ? import <nixpkgs> { }, home-manager ? <home-manager>, config ? null, isFlake ? false }:

with pkgs.lib;

let
  defaultConfigFile = "${builtins.getEnv "HOME"}/.config/nixpkgs/nix-on-droid.nix";

  hmPath = if home-manager ? install then
    pkgs.lib.warn "Passing an initialized home-manager is useless - The overridden pkgs will not be used" home-manager.path
  else home-manager;

  configModule =
    if config != null                             then config
    else if builtins.pathExists defaultConfigFile then defaultConfigFile
    else if pkgs.config ? nix-on-droid            then pkgs.config.nix-on-droid
    else throw "No config file found! Create one in ~/.config/nixpkgs/nix-on-droid.nix";

  rawModule = evalModules {
    modules = [
      {
        _module.args.home-manager = hmPath;
        _module.args.pkgs = mkDefault pkgs;
        _module.args.isFlake = isFlake;
      }
      configModule
    ] ++ import ./module-list.nix { inherit pkgs isFlake; };
  };

  failedAssertions = map (x: x.message) (filter (x: !x.assertion) rawModule.config.assertions);

  module =
    if failedAssertions != []
    then throw "\nFailed assertions:\n${concatMapStringsSep "\n" (x: "- ${x}") failedAssertions}"
    else showWarnings rawModule.config.warnings rawModule;
in

{
  inherit (module.config.build) activationPackage;
  inherit (module) config options;
}
