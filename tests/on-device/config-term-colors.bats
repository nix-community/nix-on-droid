# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

load lib

setup() {
  _setup
  [[ ! -d $HOME/.termux ]]
  mkdir $HOME/.termux

  cat > $HOME/.termux/colors.properties.refl <<EOF
background=#FFFFFF
color0=#00FF00
color15=#00FF15
cursor=#FF0000
foreground=#000000
EOF
  echo 'background = #012345' > $HOME/.termux/colors.properties.refs
}

teardown() {
  rm -f $HOME/.termux/colors.properties
  rm -f $HOME/.termux/colors.properties.refs
  rm -f $HOME/.termux/colors.properties.refl
  rm -f $HOME/.termux/colors.properties.bak
  rm -fd $HOME/.termux
}

@test 'specifying colors works (no backup)' {
  [[ ! -e $HOME/.termux/colors.properties ]]
  [[ ! -e $HOME/.termux/colors.properties.bak ]]

  cp \
    "$ON_DEVICE_TESTS_DIR/config-term-colors.nix" \
    ~/.config/nixpkgs/nix-on-droid.nix
  nix-on-droid switch
  _diff -u $HOME/.termux/colors.properties $HOME/.termux/colors.properties.refl

  [[ -e $HOME/.termux/colors.properties ]]
  [[ ! -e $HOME/.termux/colors.properties.bak ]]

  switch_to_default_config

  [[ ! -e $HOME/.termux/colors.properties ]]
  [[ ! -e $HOME/.termux/colors.properties.bak ]]
}

@test 'specifying colors works (backup)' {
  cat $HOME/.termux/colors.properties.refs > $HOME/.termux/colors.properties

  [[ -e $HOME/.termux/colors.properties ]]
  [[ ! -e $HOME/.termux/colors.properties.bak ]]

  cp \
    "$ON_DEVICE_TESTS_DIR/config-term-colors.nix" \
    ~/.config/nixpkgs/nix-on-droid.nix
  nix-on-droid switch

  [[ -e $HOME/.termux/colors.properties ]]
  [[ -e $HOME/.termux/colors.properties.bak ]]
  _diff -u $HOME/.termux/colors.properties $HOME/.termux/colors.properties.refl
  _diff -u $HOME/.termux/colors.properties.bak \
    $HOME/.termux/colors.properties.refs

  switch_to_default_config

  [[ -e $HOME/.termux/colors.properties ]]
  [[ ! -e $HOME/.termux/colors.properties.bak ]]
}

@test 'specifying a wrong keyword for color fails' {
  [[ ! -e $HOME/.termux/colors.properties ]]
  [[ ! -e $HOME/.termux/colors.properties.bak ]]

  cat $HOME/.termux/colors.properties.refs > $HOME/.termux/colors.properties
  _sed 's|color0|color16|' \
    "$ON_DEVICE_TESTS_DIR/config-term-colors.nix" \
    > ~/.config/nixpkgs/nix-on-droid.nix
  run nix-on-droid switch
  [[ $status -eq 1 ]]
  [[ $output =~ \
    \`terminal.colors\`\ only\ accepts\ the\ following\ attributes: ]]

  switch_to_default_config

  [[ -e $HOME/.termux/colors.properties ]]
  [[ ! -e $HOME/.termux/colors.properties.bak ]]
  _diff -u $HOME/.termux/colors.properties $HOME/.termux/colors.properties.refs
}
