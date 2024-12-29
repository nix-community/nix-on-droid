# Nix-on-Droid

[<img src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png"
    alt="Get it on F-Droid"
    height="80">](https://f-droid.org/packages/com.termux.nix)

Nix package manager on Android, in a single-click installable package. This is
not full [NixOS](https://nixos.org/) running inside Android, but you get easy
access to [nixpkgs](https://github.com/NixOS/nixpkgs)' vast collection of
(precompiled!) software and the best package manager under the sun. It's
prototype-grade quality as of now, but hey, it works!

It does not require root, user namespaces support or disabling SELinux,
but it relies on `proot` and other hacks instead.
It uses [a fork](https://github.com/nix-community/nix-on-droid-app)
of [Termux-the-terminal-emulator app](https://github.com/termux/termux-app),
but has no relation to [Termux-the-distro](https://termux.com/).
Please do not pester Termux folks about Nix-on-Droid.

This repository contains:

1. Nix expressions that generate a bootstrap zipball,
   which is then used to install Nix package manager on Android
   along with the `nix-on-droid` executable.
2. A module system for configuring the local Nix-on-Droid installation directly
   on the device.

It is only tested with aarch64 (64-bit ARM devices).
It also used to compile for i686 devices, but the developers don't own any
and nobody has reported whether it actually worked or not,
so it's no longer built unless a user shows up.
Sorry, it would not work on 32-bit ARM devices
and it's not an easy feat to pull off.


## Try it out

[Install it from F-Droid](https://f-droid.org/packages/com.termux.nix),
launch the app, press OK,
expect many hundreds megabytes of downloads to happen.


## Nix-on-Droid and the module system

### Config file

The Nix-on-Droid system can be managed through a custom config
file in `~/.config/nixpkgs/nix-on-droid.nix` as generated on first build,
for example:

```nix
{ pkgs, ... }:

{
  environment.packages = [ pkgs.vim ];
  system.stateVersion = "24.11";
}
```

An alternative location is `~/.config/nixpkgs/config.nix` with the key
`nix-on-droid`, for example:

```nix
{
  nix-on-droid =
    { pkgs, ... }:

    {
      environment.packages = [ pkgs.vim ];
      system.stateVersion = "24.11";
    };
}
```

See <https://nix-community.github.io/nix-on-droid/> for list of all available options.

### [`home-manager`](https://github.com/nix-community/home-manager) integration

To enable `home-manager` you simply need to follow the instructions already provided in the example `nix-on-droid.nix`:

1.  Add `home-manager` channel:
    ```sh
    nix-channel --add https://github.com/nix-community/home-manager/archive/release-24.11.tar.gz home-manager
    nix-channel --update
    ```
2.  Configure `home-manager`:
    ```nix
    { pkgs, ... }:

    {
      # Read Nix-on-Droid changelog before changing this value
      system.stateVersion = "24.11";

      # insert Nix-on-Droid config

      home-manager.config =
        { pkgs, ... }:
        {
          # Read home-manager changelog before changing this value
          home.stateVersion = "24.11";

          # insert home-manager config
        };

      # or if you have a separate home.nix already present:
      home-manager.config = ./home.nix;
    }
    ```

### `nix-on-droid` executable

This executable is responsible for activating new configurations:
Use `nix-on-droid switch` to activate the current configuration and
`nix-on-droid rollback` to rollback to the latest build.

For more information, please run `nix-on-droid help`.


## Build Nix-on-Droid on your own

The [terminal emulator part](https://github.com/nix-community/nix-on-droid-app)
is probably not interesting for you, just download and use a prebuilt one.
If you really want to rebuild it, you can just use Android Studio for that.

The zipball generation is probably what you are after.
Get an x86_64 computer with flake-enabled Nix.

> **tl;dr**: Use the deploy app like the following which executes all steps mentioned below:
>
> ```sh
> nix run ".#deploy" -- <public_url> <rsync_target>
> # or run the following for explanation of this script
> nix run ".#deploy"
> ```

Run

```sh
nix build ".#bootstrapZip-aarch64" --impure
```

Put the zip file from `result` on some HTTP server
and specify the parent directory URL during the installation.
To re-trigger the installation, you can use
'clear data' on the Android app (after backing stuff up, obviously).

If you want to change the Nix-on-Droid channel to your custom one,
you can do that either with `nix-channel` after the installation,
or by setting the environment variable `NIX_ON_DROID_CHANNEL_URL`.
Other environment variables are `NIXPKGS_CHANNEL_URL` an
`NIX_ON_DROID_FLAKE_URL`.

**Note**: The `proot` binary is not built on the android device
(NDK is required for building it, and it's not available on mobile platforms).
The way we work around it is to push proot derivation to cachix.
The current workaround is to hardcode the path to the wanted `proot` nix store
path in `modules/environment/login/default.nix`. During evaluation time on
the android device this store path will be downloaded from the binary cache
(<https://nix-on-droid.cachix.org/>). This in return means the `proot`
derivation has to be present there or in any other binary cache configured
in the `nix.conf` on the device.

Obviously it's an annoyance if one wants to fork this repo and test something.
To minimize the hassle with this scenario, proot derivation is also bundled
with the bootstrap zipball. This way you only need your own binary cache
if you are planning to maintain a long-term fork that users can update from.
In case you only care about updates through wiping the data,
or are forking to submit a one-off pull request,
you shouldn't need a binary cache for that.

## Nix flakes

**Note:** Nix flake support is still experimental at the moment and subject to change.

### Examples / templates

A minimal example could look like the following:

```nix
{
  description = "Minimal example of Nix-on-Droid system config.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-on-droid }: {

    nixOnDroidConfigurations.default = nix-on-droid.lib.nixOnDroidConfiguration {
      pkgs = import nixpkgs { system = "aarch64-linux"; };
      modules = [ ./nix-on-droid.nix ];
    };

  };
}
```

For more examples and nix flake templates, see [`templates`](./templates) directory or explore with:

```sh
nix flake init --template github:nix-community/nix-on-droid#advanced
```

### Usage with `nix-on-droid`

Use `nix-on-droid switch --flake path/to/flake#device` to build and activate your configuration (`path/to/flake#device`
will expand to `.#nixOnDroidConfigurations.device`). If you run `nix-on-droid switch --flake path/to/flake`, the
`default` configuration will be used.

**Note:** Currently, Nix-on-Droid can not be built with an pure flake build because of hardcoded store paths for proot.
Therefore, every evaluation of a flake configuration will be executed with `--impure` flag. (This behaviour will be
dropped as soon as the default setup does not require it anymore.)

## Testing

In the [./tests/on-device](./tests/on-device) directory, there is small set
of [bats](https://github.com/bats-core/bats-core) tests
that can be executed on a real or emulated android device.

To run the tests, execute

```sh
nix-on-droid on-device-test
```

**Note:** This currently requires a channel setup and should only be executed on
clean, disposable installations.

## Tips

* To grant the app access to the storage, use the toggle in the app settings
  (reachable from Android settings).
* If the terminal freezes, use 'Acquire wakelock' button in the notification
  and/or tone down your device's aggressive power saving measures.
* We have a [wiki](https://github.com/nix-community/nix-on-droid/wiki)
  with tips and success stories, you're encouraged to add yours as well.


## Technical overview

OK, real brief.

Developer's device:

1. `proot` for the target platform is cross-compiled against `bionic`,
   (to fake file paths like `/nix/store`; think 'userspace `chroot`')
2. Target `nix` is taken from the original release tarball
3. Target `nix` database is initialized
4. Support scripts and config files are built with `nix` and the Nix-on-Droid
   module system
5. From these, a bootstrap zipball is built and published on an HTTP server

User's device:

6. Android app is installed and launched, bootstrap URL is entered
7. Bootstrap zipball gets downloaded and unpacked
8. 'First boot' begins, Nix builds the environment
   (or, possibly, pulls it from Cachix)
9. Nix installs the environment (login scripts, config files, etc.)

You can refer to a
[NixCon 2019 presentation talk](https://nix-on-droid.unboiled.info/nixcon-2019-nix-on-droid.slides.pdf)
for a more extensive overview of the subject.


## Licensing and credits

Licensed under MIT License, see LICENSE.
Copyright (c) 2019-2021 Alexander Sosedkin and other contributors, see AUTHORS.

Two rewrites ago it was based off the official Nix install script
(https://nixos.org/nix/install),
presumably written by Eelco Dolstra.

Is deployed and used with [a fork](https://github.com/nix-community/nix-on-droid-app)
of [Termux-the-terminal-emulator app](https://github.com/termux/termux-app),
but has no relation to Termux-the-distro.

Previous project that did use Termux-the-distro:
https://github.com/t184256/nix-in-termux
