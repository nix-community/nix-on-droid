# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ targetSystem ? builtins.currentSystem  # system to compile for
, config ? null
, extraSpecialArgs ? { }
, pkgs ? import <nixpkgs> { }
, home-manager-path ? <home-manager>
, isFlake ? false
}:

with pkgs.lib;

let
  defaultConfigFile = "${builtins.getEnv "HOME"}/.config/nixpkgs/nix-on-droid.nix";

  configModule =
    if config != null then config
    else if builtins.pathExists defaultConfigFile then defaultConfigFile
    else pkgs.config.nix-on-droid or (throw "No config file found! Create one in ~/.config/nixpkgs/nix-on-droid.nix");

  nodModules = import ./module-list.nix {
    inherit pkgs home-manager-path isFlake targetSystem;
  };

  rawModule = evalModules {
    modules = [ configModule ] ++ nodModules;
    specialArgs = extraSpecialArgs;
  };

  failedAssertions = map (x: x.message) (filter (x: !x.assertion) rawModule.config.assertions);

  module =
    if failedAssertions != [ ]
    then throw "\nFailed assertions:\n${concatMapStringsSep "\n" (x: "- ${x}") failedAssertions}"
    else showWarnings rawModule.config.warnings rawModule;
in

{
  inherit (module.config.build) activationPackage;
  inherit (module) config options;
  inherit pkgs;
}
