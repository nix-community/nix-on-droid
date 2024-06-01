# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

load lib

@test 'android-integration options can be used' {
  run ! command -v am

  cp \
    "$ON_DEVICE_TESTS_DIR/config-android-integration.nix" \
    ~/.config/nixpkgs/nix-on-droid.nix
  nix-on-droid switch

  command -v am

  switch_to_default_config
}
