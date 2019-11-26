# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ pkgs ? import <nixpkgs> { }, initialBuild ? false, config ? { } }:

with pkgs.lib;

let
  homeDir = builtins.getEnv "HOME";
  configFile = homeDir + "/.config/nixpkgs/nix-on-droid.nix";

  hasConfigFile = builtins.pathExists configFile;

  rawModule = evalModules {
    modules = [
      {
        _module.args = { inherit pkgs; };
      }
    ]
    ++ optional (!initialBuild && hasConfigFile) configFile
    ++ optional (!initialBuild && !hasConfigFile && pkgs.config ? nix-on-droid) pkgs.config.nix-on-droid
    ++ optional initialBuild config
    ++ import ./module-list.nix;
  };

  failedAssertions = map (x: x.message) (filter (x: !x.assertion) rawModule.config.assertions);

  module =
    if failedAssertions != []
    then throw "\nFailed assertions:\n${concatMapStringsSep "\n" (x: "- ${x}") failedAssertions}"
    else showWarnings rawModule.config.warnings rawModule;
in

{
  inherit (module.config.build) activationPackage;
  inherit (module) config;
}
