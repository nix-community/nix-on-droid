# Nix-on-Droid

Nix on Android, in a single-click installable package.
It's kind of a mess for now, but hey, it works!

This script installs Nix package manager on Android.
It does not require root, user namespaces support or disabling SELinux,
but it relies on proot and numerous other hacks instead.
It uses [a fork](https://github.com/t184256/nix-on-droid-app)
of [Termux-the-terminal-emulator app](https://github.com/termux/termux-app),
but has no relation to Termux-the-distro.
Please do not pester Termux folks about my stuff.

Only tested with aarch64, may also accidentally work on x86.
Sorry, it would not work on 32-bit ARM devices.

This repository contains the script
that is responsible for the initial bootstrap zipball generation.

## Try it out

Prebuilt stuff resides at https://nix-on-droid.unboiled.info


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

Previous project that used Termux-the-distro:
https://github.com/t184256/nix-in-termux

Based off the official Nix install script (https://nixos.org/nix/install),
presumably written by Eelco Dolstra.
