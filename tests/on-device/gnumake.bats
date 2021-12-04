# Copyright (c) 2019-2021, see AUTHORS. Licensed under MIT License, see LICENSE.

@test 'GNU Make is functional' {
  TEMPDIR=/tmp/.tmp-gnumake.$$
  mkdir -p "$TEMPDIR"
  echo -e 'x:\n\techo desired output > x' > "$TEMPDIR/Makefile"
  nix-shell -p gnumake --run "make -C $TEMPDIR x"
  [[ -e "$TEMPDIR/x" ]]
  [[ "$(cat "$TEMPDIR/x")" == 'desired output' ]]
}

teardown() {
  rm -r "$TEMPDIR"
}
