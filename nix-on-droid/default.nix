# Licensed under GNU Lesser General Public License v3 or later, see COPYING.
# Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

{ bash, coreutils, nix, runCommand }:

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
