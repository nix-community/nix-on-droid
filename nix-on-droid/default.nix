# Copyright (c) 2019-2020, see AUTHORS. Licensed under MIT License, see LICENSE.

{ bash, coreutils, nix, nix_2_4, runCommand }:

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
      --subst-var-by nix "${nix}" \
      --subst-var-by nix24 "${nix_2_4}"
  ''
