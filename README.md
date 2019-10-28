# Nix-on-Droid

[<img src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png"
    alt="Get it on F-Droid"
    height="80">](https://f-droid.org/packages/com.termux.nix)

Nix package manager on Android, in a single-click installable package.
This is not full NixOS running inside Android,
but you get easy access to Nixpkgs' vast collection of (precompiled!) software
and the best package manager under the sun.
It's prototype-grade quality as of now, but hey, it works!

It does not require root, user namespaces support or disabling SELinux,
but it relies on `proot` and other hacks instead.
It uses [a fork](https://github.com/t184256/nix-on-droid-app)
of [Termux-the-terminal-emulator app](https://github.com/termux/termux-app),
but has no relation to Termux-the-distro.
Please do not pester Termux folks about Nix-on-Droid.

This repository contains:

1. Nix expressions that generate a bootstrap zipball,
   which is then used to install Nix package manager on Android
   along with some support scripts and configuration files.
2. A channel that can be later used to deliver updates
   for the latter.

It is only tested with aarch64 (64-bit ARM devices).
It may also support x86 devices, but the developers don't own one
and nobody has reported whether it actually works or not.

Sorry, it would not work on 32-bit ARM devices
and it's not an easy feat to pull off.


## Try it out

Prebuilt stuff resides at https://nix-on-droid.unboiled.info
Install the APK, launch the app, press OK.


## Build stuff on your own

The [terminal emulator part](https://github.com/t184256/nix-on-droid-app)
is probably not interesting for you, just download and use a prebuilt one.
If you really want to rebuild it, you can just use Android Studio for that.

The zipball generation is probably what you are after.
Get an x86_64 computer with Nix. Run one of the following:
```
nix build -f ./src --argstr arch aarch64 bootstrapZip
nix build -f ./src --argstr arch i686 bootstrapZip
```

Put the zip file from `result` on some HTTP server
and specify the parent directory URL during the installation.
To re-trigger the installation, you can use
'clear data' on the Android app (after backing stuff up, obviously).
Now that we have an upgrade path for everything except for the `proot` binary,
this should not be needed anymore.

If you want to change the nix-on-droid channel to your custom one,
you can do that either with `nix-channel` after the installation,
or by using `--argstr nixOnDroidChannelUrl <URL>`.


## Tips

* Run `hm-install`. Otherwise you could find the system a bit too barebones.
* If you don't want to, read the tips that are displayed at the beginning
  of each new session.
* To grant the app access to the storage, use the toggle in the app settings
  (reachable from Android settings).
* If the terminal freezes, use 'Acquire wakelock' button in the notification
  and/or tone down your device's aggressive power saving measures.
* If you have name resolution issues,
  start with specifying your nameservers in `/etc/resolv.conf`.


## Technical overview

OK, real brief.

Developer's device:

0. Required tools are compiled or downloaded in pre-compiled form
1. `proot` for the target platform is cross-compiled against `bionic`,
   (to fake file paths like `/nix/store`; think 'userspace `chroot`')
2. Target `nix` is taken from the original release tarball
3. Target `nix` database is initialized (with host `proot` and `qemu-user`)
4. Support scripts and config files are built with `nix`
5. From these, a bootstrap zipball is built and published on an HTTP server

User's device:

6. Android app is installed and launched, bootstrap URL is entered
7. Bootstrap zipball gets downloaded and unpacked
8. 'First boot' begins, Nix builds the environment
   (or, possibly, pulls it from Cachix)
9. Nix installs the environment, now it manages every file (except `proot`)
10. The user is given an option
    either to proceed with this minimal installation of Nix,
    or to install home-manager to manage the environment
    in a more declarative fashion (recommended).

You can refer to a
[NixCon 2019 presentation talk](https://nix-on-droid.unboiled.info/nixcon-2019-nix-on-droid.slides.pdf)
for a more extensive overview of the subject.


## Licensing and credits

Licensed under GNU Lesser General Public License v3 or later, see COPYING.
Copyright (c) 2019 Alexander Sosedkin and other contributors, see AUTHORS.

Initially based off the official Nix install script
(https://nixos.org/nix/install),
presumably written by Eelco Dolstra.

Is deployed and used with [a fork](https://github.com/t184256/nix-on-droid-app)
of [Termux-the-terminal-emulator app](https://github.com/termux/termux-app),
but has no relation to Termux-the-distro.

Previous project that did use Termux-the-distro:
https://github.com/t184256/nix-in-termux
