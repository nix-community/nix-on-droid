# Copyright (c) 2019-2021, see AUTHORS. Licensed under MIT License, see LICENSE.

setup() {
  if [[ -z "$ON_DEVICE_TESTS_SETUP" ]]; then
    CHANNEL_DIR="$(nix-instantiate --eval --expr '<nix-on-droid>')"
    ON_DEVICE_TESTS_DIR="$CHANNEL_DIR/tests/on-device"

    while read -r channel_line; do
      if [[ "$channel_line" =~ nix-on-droid[[:space:]]+(.*) ]]; then
        CHANNEL_URL=${BASH_REMATCH[1]}
      fi
    done < <(nix-channel --list)
    echo "parsing detected channel url: $CHANNEL_URL"
    if [[ "$CHANNEL_URL" =~ https://github.com/(.+)/(.+)/archive/(.+)\.tar\.gz ]]; then
      REPO_USER=${BASH_REMATCH[1]}
      REPO_NAME=${BASH_REMATCH[2]}
      REPO_BRANCH=${BASH_REMATCH[3]}
      FLAKE_URL=github:$REPO_USER/$REPO_NAME/$REPO_BRANCH
    elif [[ "$CHANNEL_URL" == file:///n-o-d/archive.tar.gz ]]; then
      FLAKE_URL=/n-o-d/unpacked
    fi
    echo "autodetected flake url: $FLAKE_URL"

    ON_DEVICE_TESTS_SETUP=1
  fi

  # restore to pre-testing generation before the start of each test
  $DEFAULT_ACTIVATE_SCRIPT
}

assert_command() {
  for cmd_name; do
    command -v "$cmd_name"
  done
}

assert_no_command() {
  for cmd_name; do
    run command -v "$cmd_name"
    [[ "$status" == 1 ]]
  done
}

switch_to_default_config() {
  rm -rf ~/.config/nix ~/.config/nixpkgs
  mkdir -p ~/.config/nix ~/.config/nixpkgs
  cat "$CHANNEL_DIR/modules/environment/login/nix-on-droid.nix.default" \
    > ~/.config/nixpkgs/nix-on-droid.nix
  nix-on-droid switch

  assert_command nix-on-droid nix-shell bash vi find
  assert_no_command dash xonsh zsh
}
