# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

# call _setup when defining a setup function in your test
_setup() {
  if [[ -z "$ON_DEVICE_TESTS_SETUP" ]]; then
    CHANNEL_DIR="$(nix-instantiate --eval --expr '<nix-on-droid>')"
    ON_DEVICE_TESTS_DIR="$CHANNEL_DIR/tests/on-device"

    local channelUrl
    while read -r channel_line; do
      if [[ "$channel_line" =~ nix-on-droid[[:space:]]+(.*) ]]; then
        channelUrl=${BASH_REMATCH[1]}
      fi
    done < <(nix-channel --list)
    echo "parsing detected channel url: $channelUrl"
    if [[ "$channelUrl" =~ https://github.com/(.+)/(.+)/archive/(.+)\.tar\.gz ]]; then
      local repoUser=${BASH_REMATCH[1]}
      local repoName=${BASH_REMATCH[2]}
      local repoBranch=${BASH_REMATCH[3]}
      FLAKE_URL=github:$repoUser/$repoName/$repoBranch
    elif [[ "$channelUrl" == file:///n-o-d/archive.tar.gz ]]; then
      FLAKE_URL=/n-o-d/unpacked
    else
      FLAKE_URL="$channelUrl"
    fi
    echo "autodetected flake url: $FLAKE_URL"

    ON_DEVICE_TESTS_SETUP=1
  fi

  # restore to pre-testing generation before the start of each test
  $DEFAULT_ACTIVATE_SCRIPT
  rm -rf ~/.config/nixpkgs/*

  # build and activate the version of nix-on-droid that is subject to test
  switch_to_default_config
}

setup() {
  _setup
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
  cat "$CHANNEL_DIR/modules/environment/login/nix-on-droid.nix.default" \
    > ~/.config/nixpkgs/nix-on-droid.nix
  nix-on-droid switch
}

_sed() {
  local storePath
  storePath="$(nix-build "<nixpkgs>" --no-out-link --attr gnused)"
  "${storePath}/bin/sed" "$@"
}
