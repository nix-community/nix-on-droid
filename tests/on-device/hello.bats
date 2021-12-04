# Copyright (c) 2019-2021, see AUTHORS. Licensed under MIT License, see LICENSE.

@test 'GNU Hello is functional' {
  out=$(nix-shell -p hello --run hello)
  [[ "$out" == 'Hello, world!' ]]
  [[ "$status" -eq 0 ]]
}
