# Copyright (c) 2019-2021, see AUTHORS. Licensed under MIT License, see LICENSE.

load lib

@test 'flake example works' {
  # assertions to verify initial state is as expected
  assert_command vi
  assert_no_command unzip

  # set up / build / activate the configuration
  _sed \
    -e 's/vim/nano/' \
    -e 's/#unzip/unzip/' \
    "$CHANNEL_DIR/modules/environment/login/nix-on-droid.nix.default" \
    > ~/.config/nixpkgs/nix-on-droid.nix

  _sed "s|<<FLAKE_URL>>|$FLAKE_URL|g" \
    "$ON_DEVICE_TESTS_DIR/config-flake.nix" \
    > ~/.config/nixpkgs/flake.nix

  nix-on-droid switch --flake ~/.config/nixpkgs#device

  # test presence of several crucial commands
  assert_command nix-on-droid nix-shell bash

  # test that nano has replaced vi and unzip has appeared in $PATH
  assert_command nano unzip
  assert_no_command vi

  # check that reverting works too
  rm -f ~/.config/nix/nix.conf ~/.config/nixpkgs/flake.nix
  switch_to_default_config
  assert_command vi
  assert_no_command unzip
}
