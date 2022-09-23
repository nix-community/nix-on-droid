# Changelog

## Release 22.11 (unreleased)

* Terminal font now should be specified using `terminal.font` option,
  set it to a TTF file to apply a font.
  An in-app `Styling` option will no longer work.
  Previously present file will be backed up to `~/.termux/font.ttf.bak`.
* `/proc/uptime` is now faked with a stub that allows unpatched `ps` to work.

## Release 22.05

### Compatibility considerations

* `/proc/stat` is now faked with a stub that allows unpatched `htop` to work.
* `--sysvipc` `proot` extension has been enabled
  to facilitate shared memory interprocess communication.

## Release 21.11

### New Options

* The `nix.package` can be used to set the system-wide nix package.

## Removed Options

* The `system.workaround.make-posix-spawn.enable` has been removed.
* i686 support has been removed.

## Release 21.05

### New Options

* The `/etc/nix/nix.conf` file is now fully configurable with the
  new options `nix.*`.

### Deprecations

* `system.workaround.make-posix-spawn.enable = true;` is no longer needed
  is deprecated.
* i686 support will be deprecated in the next release
  unless somebody steps up to test it.

## Release 20.09

### State version changes

These changes are only active
if the `system.stateVersion` option is set to `"20.09"` or later.

* `home-manager.useUserPackages` now defaults to `true`.
  The developers are not aware of any adverse effects so far.

### Other compatibility considerations

* Pre-module-system installations are not supported anymore with this release.
  If you are not on `release-19.09` yet,
  either or attempt an upgrade to `release-19.09`
  and follow the instructions, or backup and reinstall (preferred).

### Nix flakes support

* A `flake.nix` file was added.

### Known issues

* If `make` fails on your device with `Function not implemented`,
  report that in https://github.com/t184256/nix-on-droid/issues/91
  and consider either
  [remote building](https://github.com/t184256/nix-on-droid/wiki/Remote-building)
  or setting `system.workaround.make-posix-spawn.enable = true;`
