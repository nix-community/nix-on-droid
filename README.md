# Nix-on-Droid

Nix on Android, in a single-click installable package.
It's a bit of a mess for now, but hey, it works!

This script installs Nix package manager on Android.
It does not require root, user namespaces support or disabling SELinux,
but it relies on proot and numerous other hacks instead.
It uses [a fork](https://github.com/t184256/nix-on-droid-app)
of [Termux-the-terminal-emulator app](https://github.com/termux/termux-app),
but has no relation to Termux-the-distro.
Please do not pester Termux folks about my stuff.

Will only work with aarch64.
It should be easy to support x86 devices, but I don't own one.
Sorry, it would not work on 32-bit ARM devices
and it's probably not an easy feat to pull off.

This repository contains the script
that is responsible for the initial bootstrap zipball generation.


## Try it out

Prebuilt stuff resides at https://nix-on-droid.unboiled.info


## Building stuff on your own

The [terminal emulator part](https://github.com/t184256/nix-on-droid-app)
is probably not interesting for you, just download and use a prebuilt one.
If you really want to rebuild it, you can just use Android Studio for that.

The zipball generation script is probably what you are after.
Get an x86_64 computer with Nix
(running a reasonably recent version of NixOS would work out the best).
Modify the script, run it as `./generate_bootstrap_zipball aarch64`
or `./generate_bootstrap_zipball i686`,
put the resulting files on some HTTP server,
and specify the parent directory URL during the installation.
To re-trigger the installation, use
'clear data' on the Android app (after backing stuff up, obviously).


## Tips

* Run `nix-on-droid-install`. Otherwise it's just Nix and that's too barebones.
* If you don't want to, read the tips that are displayed at the beginning
  of each new session.
* To grant the app access to the storage, use the toggle in the app settings
  (reacheable from Android settings).
* If the terminal freezes, use 'Acquire wakelock' button in the notification
  or tone down your aggressive power saving stuff.
* If you have name resolution issues,
  start with specifying your nameservers in `/etc/resolv.conf`.


## Credits

Copyright (c) 2019 Alexander Sosedkin <monk@unboiled.info>

Based off the official Nix install script (https://nixos.org/nix/install),
presumably written by Eelco Dolstra.

Is deployed and used with [a fork](https://github.com/t184256/nix-on-droid-app)
of [Termux-the-terminal-emulator app](https://github.com/termux/termux-app),
but has no relation to Termux-the-distro.

Previous project that did use Termux-the-distro:
https://github.com/t184256/nix-in-termux

