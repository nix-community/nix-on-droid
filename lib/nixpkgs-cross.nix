# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

{}:

import ./nixpkgs-pinned.nix {
  crossSystem = {
    config = "aarch64-unknown-linux-android";
    sdkVer = "32";
    libc = "bionic";
    useAndroidPrebuilt = false;
    useLLVM = true;
    isStatic = true;
  };
}
