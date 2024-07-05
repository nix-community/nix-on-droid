# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

load lib

@test 'android-integration options can be used' {
  bats_require_minimum_version 1.5.0
  run ! command -v am
  run ! command -v termux-setup-storage
  run ! command -v termux-open-url

  cp \
    "$ON_DEVICE_TESTS_DIR/config-android-integration.nix" \
    ~/.config/nixpkgs/nix-on-droid.nix
  nix-on-droid switch

  command -v am
  command -v termux-setup-storage
  run ! command -v termux-open-url

  _sed \
    -e "s|# unsupported.enable = false;|unsupported.enable = true;|" \
    -e "s|am.enable = true;|am.enable = false;|" \
    -i ~/.config/nixpkgs/nix-on-droid.nix
  nix-on-droid switch
  run ! command -v am
  command -v termux-setup-storage
  command -v termux-open-url

  switch_to_default_config
}
