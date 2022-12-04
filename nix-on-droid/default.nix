# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

{ bash, coreutils, lib, nix, runCommand }:

runCommand
  "nix-on-droid"
{
  preferLocalBuild = true;
  allowSubstitutes = false;
}
  ''
    install -D -m755  ${./nix-on-droid.sh} $out/bin/nix-on-droid

    substituteInPlace $out/bin/nix-on-droid \
      --subst-var-by bash "${bash}" \
      --subst-var-by coreutils "${coreutils}" \
      --subst-var-by nix "${nix}"
  ''
