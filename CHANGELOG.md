# Changelog

## Release 23.05 (unreleased)

## Release 22.11

### Compatibility considerations

* Fix usage of `extraSpecialArgs`: All values were previously set in
  `_module.args` instead of passing them as `specialArgs` into `evalModules`.
  This enables usage of `specialArgs` to use in `imports` in module defintions.
* In an effort to reduce the number of arguments to `lib.nixOnDroidConfiguration`
  function in flake configurations, `system` is now inferred from `pkgs.system`
  and `config` and `extraModules` are now combined into `modules`
* The option `system.stateVersion` does not have a default value anymore.
  Previously, its default was `"19.09"` the release the state version was
  introduced.

### New Options

* Terminal font now should be specified using `terminal.font` option,
  set it to any file containing a font to apply it.
  An in-app `Styling` option will no longer work.
  Previously present file will be backed up to `~/.termux/font.ttf.bak`.
* Add option `environment.motd` to edit the startup message that is printed in
  every shell

### Other notable changes

* `/proc/uptime` is now faked with a stub that allows unpatched `ps` to work.
* Refactored project for flakes usage (still supporting non-flake setups on
  device, but bootstrap zip ball creation and running tests via fakedroid
  requires flake setup)
* Add support for `nix profile` managed profiles
* Add possibilty to bootstrap Nix-on-Droid with flakes via prompt on initial
  boot
* For flake setups, the output `nixOnDroidConfigurations.default` will be used
  when `nix-on-droid switch --flake path/to/flake` is called without attribute
  name
* Add html and man pages with all available options, see <https://t184256.github.io/nix-on-droid/>
  and `nix build github:t184256/nix-on-droid#manPages`

## Release 22.05

### Compatibility considerations

* `/proc/stat` is now faked with a stub that allows unpatched `htop` to work.
* `--sysvipc` `proot` extension has been enabled
  to facilitate shared memory interprocess communication.

## Release 21.11

### New Options

* The `nix.package` can be used to set the system-wide nix package.

### Removed Options

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
