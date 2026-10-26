# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

load lib

setup() {
  _setup
  cp ~/.nix-channels ~/.nix-channels.bak
}

teardown() {
  nix-channel --remove home-manager
  mv ~/.nix-channels.bak ~/.nix-channels

  rm -f ~/.config/example
}

@test 'using home-manager works' {
  # assertions to verify initial state is as expected
  assert_command vim
  assert_no_command dash
  [[ ! -e ~/.config/example ]]

  # set up / build / activate the configuration
  nix-channel --add https://github.com/nix-community/home-manager/archive/release-24.11.tar.gz home-manager
  nix-channel --update
  cp "$ON_DEVICE_TESTS_DIR/config-h-m.nix" ~/.config/nixpkgs/nix-on-droid.nix
  nix-on-droid switch

  # test config file
  [[ -e ~/.config/example ]]
  [[ "$(cat ~/.config/example)" == 'example config' ]]

  # test common commands presence
  assert_command nix-on-droid nix-shell bash

  # test that vim has disappeared
  assert_no_command vim

  # test dash has appeared and works
  assert_command dash
  run dash -c 'echo success; exit 42'
  [[ "$output" == success ]]
  [[ "$status" == 42 ]]

  # check that reverting works too
  switch_to_default_config
  assert_command vim
  assert_no_command unzip

  # file will be still present because home-manager needs to be set up to remove old links
  [[ -e ~/.config/example ]]
}
