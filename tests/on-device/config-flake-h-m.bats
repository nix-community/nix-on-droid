# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

load lib

@test 'flake + h-m + #134 overlays case work' {
  # assertions to verify initial state is as expected
  assert_command vim
  assert_no_command dash zsh

  # set up / build / activate the configuration
  cat "$ON_DEVICE_TESTS_DIR/config-flake-h-m.cfg.nix" \
    > ~/.config/nixpkgs/nix-on-droid.nix
  _sed "s|<<FLAKE_URL>>|$FLAKE_URL|g" \
    "$ON_DEVICE_TESTS_DIR/config-flake-h-m.flake.nix" \
    > ~/.config/nixpkgs/flake.nix

  nix-on-droid switch --flake ~/.config/nixpkgs#device

  # test presence of several crucial commands
  assert_command nix-on-droid nix-shell bash

  # test that both zsh (system) and dash (user) have appeared in $PATH
  assert_command dash zsh
  assert_no_command vim

  # check that reverting works too
  switch_to_default_config
  assert_command vim
  assert_no_command dash zsh
}
