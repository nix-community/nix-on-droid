# Copyright (c) 2019-2021, see AUTHORS. Licensed under MIT License, see LICENSE.

load lib

@test 'flake + h-m + #134 overlays case work' {
  # assertions to verify initial state is as expected
  assert_command vi
  assert_no_command dash zsh

  # set up / build / activate the configuration
  cat "$ON_DEVICE_TESTS_DIR/config-flake-h-m.cfg.nix" \
    > ~/.config/nixpkgs/nix-on-droid.nix
  _sed "s|<<FLAKE_URL>>|$FLAKE_URL|g" \
    "$ON_DEVICE_TESTS_DIR/config-flake-h-m.flake.nix" \
    > ~/.config/nixpkgs/flake.nix
  pushd ~/.config/nixpkgs
    nix-shell -p nixFlakes --run \
      'nix build \
        --extra-experimental-features nix-command \
        --extra-experimental-features flakes \
        --impure .#nix-on-droid'
    result/activate
  popd

  # test presence of several crucial commands
  assert_command nix-on-droid nix-shell bash

  # test that both zsh (system) and dash (user) have appeared in $PATH
  assert_command dash zsh
  assert_no_command vi

  # check that reverting works too
  rm -f ~/.config/nix/nix.conf ~/.config/nixpkgs/flake.nix
  switch_to_default_config
  assert_command vi
  assert_no_command dash zsh
}
