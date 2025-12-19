# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ stdenv
, fetchFromGitHub
, autoreconfHook
, makeWrapper
, gnused
, getopt
, termux-am
,
}:

stdenv.mkDerivation (finalAttrs: {
  name = "termux-tools";
  version = "1.47.1";

  src = fetchFromGitHub {
    owner = "termux";
    repo = "termux-tools";
    tag = "v${finalAttrs.version}";
    hash = "sha256-YfIxDegzIHyy62IlpSgrDz4fQiPoZNgSzXNtAk5lmn8=";
  };

  nativeBuildInputs = [
    autoreconfHook
    makeWrapper
  ];

  propagatedInputs = [ termux-am ];

  postPatch = ''
    substituteInPlace scripts/termux-setup-storage.in \
      --replace-fail "@TERMUX_HOME@" "/data/data/com.termux.nix/files/home/" \
      --replace-fail "@TERMUX_APP_PACKAGE@" "com.termux.nix"
    substituteInPlace scripts/termux-open.in \
      --replace-fail "getopt " "${getopt}/bin/getopt "
    substituteInPlace \
      scripts/termux-open.in \
      scripts/termux-wake-lock.in \
      scripts/termux-wake-unlock.in \
      --replace-fail "@TERMUX_APP_PACKAGE@.app" "com.termux.app" \
      --replace-fail "@TERMUX_APP_PACKAGE@" "com.termux.nix"
    substituteInPlace scripts/termux-reload-settings.in \
      --replace-fail "@TERMUX_APP_PACKAGE@" "com.termux.nix"
    ${gnused}/bin/sed -i 's|^am |${termux-am}/bin/am |' scripts/*

    rm --recursive doc  # manpage is half misleading, pulling pandoc is not worth it
    substituteInPlace Makefile.am \
      --replace-fail "SUBDIRS = . scripts doc mirrors motds src" "SUBDIRS = . scripts"
    substituteInPlace configure.ac \
      --replace-fail "AC_CONFIG_FILES([Makefile scripts/Makefile doc/Makefile" "AC_CONFIG_FILES([Makefile scripts/Makefile])" \
      --replace-fail "mirrors/Makefile motds/Makefile src/Makefile])" ""
  '';

  outputs = [
    "out" # all the unsupported unsorted stuff
    "setup_storage" # termux-setup-storage
    "open" # termux-open
    "open_url" # termux-open-url
    "reload_settings" # termux-reload-settings
    "wake_lock" # termux-wake-lock
    "wake_unlock" # termux-wake-unlock
    "xdg_open" # xdg-open
  ];
  postInstall = ''
    rm $out/etc/termux-login.sh
    rm $out/etc/profile.d/init-termux-properties.sh
    rm -d $out/etc/profile.d
    rm -d $out/etc

    rm $out/bin/chsh      # we offer a declarative way to change your shell
    rm $out/bin/dalvikvm  # doesn't work because we overlay /system/bin
    rm $out/bin/df        # works without the magic
    rm $out/bin/getprop   # doesn't work because we overlay /system/bin
    rm $out/bin/logcat    # doesn't work because we overlay /system/bin
    rm $out/bin/login     # we have our own, very complex login
    rm $out/bin/ping      # doesn't work because we overlay /system/bin
    rm $out/bin/ping6     # doesn't work because we overlay /system/bin
    rm $out/bin/pkg       # we use Nix
    rm $out/bin/pm        # doesn't work because we overlay /system/bin
    rm $out/bin/settings  # doesn't work because we overlay /system/bin
    rm $out/bin/su        # doesn't work because we overlay /bin
    rm $out/bin/top       # doesn't work because we overlay /system/bin

    rm $out/bin/termux-change-repo            # we use Nix
    rm $out/bin/termux-fix-shebang            # we use Nix
    rm $out/bin/termux-info                   # Termux-specific. write our own?
    rm $out/bin/termux-reset                  # untested and dangerous
    rm $out/bin/termux-restore                # untested and dangerous
    rm $out/bin/termux-setup-package-manager  # we use Nix

    mkdir -p $setup_storage/bin
    mv $out/bin/termux-setup-storage $setup_storage/bin/

    mkdir -p $open/bin
    mv $out/bin/termux-open $open/bin/

    mkdir -p $open_url/bin
    mv $out/bin/termux-open-url $open_url/bin/

    mkdir -p $reload_settings/bin
    mv $out/bin/termux-reload-settings $reload_settings/bin/

    mkdir -p $wake_lock/bin
    mv $out/bin/termux-wake-lock $wake_lock/bin/

    mkdir -p $wake_unlock/bin
    mv $out/bin/termux-wake-unlock $wake_unlock/bin/

    mkdir -p $xdg_open/bin
    rm $out/bin/xdg-open
    ln -s $open/bin/termux-open $xdg_open/bin/xdg-open

    # check that we didn't package we didn't want to
    find $out | ${gnused}/bin/sed "s|^$out|.|" | sort > effective
    echo . >> expected
    echo ./bin >> expected
    echo ./bin/termux-backup >> expected           # entirely untested
    echo ./share >> expected
    echo ./share/examples >> expected
    echo ./share/examples/termux >> expected
    echo ./share/examples/termux/termux.properties >> expected  # useful
    diff -u expected effective
  '';
})
