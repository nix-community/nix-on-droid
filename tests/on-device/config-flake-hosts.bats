# Copyright (c) 2023, see AUTHORS. Licensed under MIT License, see LICENSE.

load lib

@test 'hosts can be configured' {
  # set up / build / activate the configuration
  cat "$ON_DEVICE_TESTS_DIR/config-flake-hosts.cfg.nix" \
    > ~/.config/nixpkgs/nix-on-droid.nix
  _sed "s|<<FLAKE_URL>>|$FLAKE_URL|g" \
    "$ON_DEVICE_TESTS_DIR/config-flake.nix" \
    > ~/.config/nixpkgs/flake.nix

  nix-on-droid switch --flake ~/.config/nixpkgs#device

  # check that /etc/hosts contains configured hosts
  for entry in '::1 localhost' \
               '127.0.0.1 localhost' \
               '127.0.0.2 a b' \
               '127.0.0.3 c' \
               '127.0.0.4 d'
  do
    grep "$entry" /etc/hosts
  done
}

@test 'hosts can not map localhost' {
  # set up / build / activate the configuration
  cat "$ON_DEVICE_TESTS_DIR/config-flake-hosts-localhost.cfg.nix" \
    > ~/.config/nixpkgs/nix-on-droid.nix
  _sed "s|<<FLAKE_URL>>|$FLAKE_URL|g" \
    "$ON_DEVICE_TESTS_DIR/config-flake.nix" \
    > ~/.config/nixpkgs/flake.nix

  # check that networking.hosts can't map localhost
  run nix-on-droid switch --flake ~/.config/nixpkgs#device
  [ "$status" -eq 1 ]
}
