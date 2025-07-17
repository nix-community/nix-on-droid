# Copyright (c) 2023, see AUTHORS. Licensed under MIT License, see LICENSE.

load lib

@test 'successfully loads a config with _class="nixOnDroid"' {
  # set up / build / activate the configuration
  echo '{ config.system.stateVersion = "24.05"; _class = "nixOnDroid"; }' > ~/.config/nixpkgs/nix-on-droid.nix
  _sed -e "s|<<FLAKE_URL>>|$FLAKE_URL|g" -e "s|<<SYSTEM>>|$(detect_system)|g" \
    "$ON_DEVICE_TESTS_DIR/config-flake.nix" \
    > ~/.config/nixpkgs/flake.nix

  nix-on-droid switch --flake ~/.config/nixpkgs#device
}

@test 'fails to load a config with _class="nixos"' {
  # set up / build / activate the configuration
  echo '{ config.system.stateVersion = "24.05"; _class = "nixos"; }' > ~/.config/nixpkgs/nix-on-droid.nix
  _sed -e "s|<<FLAKE_URL>>|$FLAKE_URL|g" -e "s|<<SYSTEM>>|$(detect_system)|g" \
    "$ON_DEVICE_TESTS_DIR/config-flake.nix" \
    > ~/.config/nixpkgs/flake.nix

  # check that networking.hosts can't map localhost
  run nix-on-droid switch --flake ~/.config/nixpkgs#device
  [ "$status" -eq 1 ]
}
