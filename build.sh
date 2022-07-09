#!/usr/bin/env bash

# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

# If you want to change something in this repo and now you're wondering
# how to recompile Nix-on-Droid with your changes and put it to your device,
# wonder no more!

# One of the simplest scenarios would be forking it on GitHub:
# * fork it to github.com/YOUR_USERNAME/nix-on-droid
# * change something, commit your changes to some BRANCH
# * push it
# * nix build --show-trace -f pkgs \
#       --argstr nixOnDroidChannelURL \
#       https://github.com/YOUR_USERNAME/nix-on-droid/archive/BRANCH.tar.gz \
#       bootstrapZip -o out/nix-on-droid-aarch64
# * put out/nix-on-droid-aarch64/bootstrap-aarch64.zip to some HTTP server
# * install the app and, on first startup, enter the URL of the directory
#   containing the resulting zip file, start the installation

# The zipfile will be used to kickstart the installation,
# it will build what's available from nixOnDroidChannelURL you've specified,
# (i.e., what you've pushed to BRANCH), and the resulting system will be
# subscribed to the updates that you push to the specified BRANCH of your fork.

# If you just want to change something and test it, this should be enough.
# This probably doesn't warrant a script, you can just run the command above
# and call it a day. If you don't need to maintain a long-term fork, do it.
# You can stop reading here.

# But, in some cases, you need to be concerned with more things than that.
# Maybe you don't want to use GitHub.
# Maybe you don't want to bother with forking or pushing.
# Maybe you want to automate and streamline the whole process.
# If that's the case, read more to find out what to do and how to do it.

# ---

# There are three distinct things built from this repo:
# 1. A zipfile with the installer (zipball),
#    which has to be downloaded from some web server during the installation,
#    the user is asked for location on the initial app startup.
#    (https://nix-on-droid.unboiled.info/bootstrap + /bootstrap-$arch.zip
#     for the official builds, the user can override the first part).
#    Needed only once, doesn't matter after the installation.
# 2. Sources for building nix-on-droid-specific packages on device,
#    which also have to be put somewhere on the web.  If you push to GitHub,
#    you already have them published in a nix-channel usable form.
#    But it's also possible to point to an arbitrary URL.
#    The initial location is baked into the installer tarball,
#    it's later reconfigurable with 'nix-channel'.
#    This is how most updates are shipped.

# That's a lot of stuff, and the developers have come up with workflows
# progressively more rich and twisted than `nix build ... && rsync ...`.
# Feel free to pick up tricks below and/or modify the script to suit your needs.

set -e

arches=${arches:-aarch64}  # whitespace-separated list of architectures to build

# Create/clear the output directory.
mkdir -p out
rm -f out/*

for arch in $arches; do
    if [[ -z $channel_url ]]; then
        # It is enough to push your changes to GitHub to
        # you have nix-on-droid sources downloadable from there.
        # Let's figure out the URL.
        branch=${branch:-$(git rev-parse --abbrev-ref HEAD)}  # overrideable
        tracking=$(git config branch.${branch}.remote)
        url=$(git remote get-url $tracking)
        if [[ -z "$channel_url" ]]; then
            if [[ -z "$github_repository" ]]; then
                if [[ $url =~ git@github.com:* ]]; then
                   autodetected_repository=${url##git@github.com:}
                elif [[ $url =~ https://github.com/* ]]; then
                   autodetected_repository=${url##https://github.com}
                fi
                if [[ $autodetected_repository =~ \.git ]]; then
                   autodetected_repository=${autodetected_repository%%.git}
                fi
                echo $arch: autodetected repository: $autodetected_repository
                if [[ $autodetected_repository == 't184256/nix-on-droid' ]]; then
                   if [[ $USER != 'monk' ]]; then
                       echo 'Failed to autodetect the URL of your fork.'
                       echo 'Set either github_repository or channel_url.'
                       exit 1
                   fi
                fi
            channel_url=${channel_url:-https://github.com/$autodetected_repository/archive/$branch.tar.gz}
            echo $arch: autodetected channel URL: $channel_url
            fi
        fi
    else
    # Build channel tarball,
    # later optionally push it somewhere along with the installation zipball
       :
    fi


### not annotated yet ###


nixOnDroidChannelURL=${nixOnDroidChannelURL:-$channel_url}

    echo $arch: building nix-on-droid...
    nix build --show-trace -f pkgs --argstr arch $arch --argstr nixOnDroidChannelURL $nixOnDroidChannelURL bootstrapZip -o out/nix-on-droid-$arch

    if [ -z "$rsync_to" ]; then
        echo "Done. Now put out/nix-on-droid-$arch/bootstrap-$arch.zip on some HTTP server and point the app to it. Good luck!"
    else
        if [ $branch == master ]; then
            tgt="$rsync_to/bootstrap/"
        else
            tgt="$rsync_to/bootstrap-$branch/"
        fi
        echo rsyncing to $tgt...
        rsync -vP out/nix-on-droid-$arch/bootstrap-*.zip $tgt
    fi
done
