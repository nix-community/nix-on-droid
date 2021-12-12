# Copyright (c) 2019-2021, see AUTHORS. Licensed under MIT License, see LICENSE.

load lib

@test 'flake example works' {
  # assertions to verify initial state is as expected
  assert_command vi
  assert_no_command unzip

  # set up / build / activate the configuration
  nix-shell -p gnused --run \
    "sed \
         -e s/vim/nano/ \
         -e s/#unzip/unzip/ \
         < '$CHANNEL_DIR/modules/environment/login/nix-on-droid.nix.default' \
         > ~/.config/nixpkgs/nix-on-droid.nix"

  nix-shell -p gnused --run \
    "sed 's|<<FLAKE_URL>>|$FLAKE_URL|g' \
         < '$ON_DEVICE_TESTS_DIR/config-flake.nix' \
         > ~/.config/nixpkgs/flake.nix"

  # this is more cumbersome than options,
  # but this is what we recommend to users, so taking the hard way
  echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
  pushd ~/.config/nixpkgs
    nix-shell -p nixFlakes --run 'nix build .#nix-on-droid --impure'
    result/activate
  popd

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
