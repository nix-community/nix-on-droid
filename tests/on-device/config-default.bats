# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

load lib

@test 'default config can be switched into' {
  switch_to_default_config

  assert_command nix-on-droid nix-shell bash vim find
  assert_no_command dash xonsh zsh
}
