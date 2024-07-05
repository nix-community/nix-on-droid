# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ stdenvNoCC
, fetchFromGitHub
, autoreconfHook
, makeWrapper
, gnused
, getopt
, termux-am
}:

stdenvNoCC.mkDerivation rec {
  name = "termux-tools";
  version = "1.42.4";
  src = fetchFromGitHub {
    owner = "termux";
    repo = "termux-tools";
    rev = "v${version}";
    sha256 = "sha256-LkkeaEQcY8HgunBYAg3Ymn5xYPvrGqGNCZTd/NyIOKY=";
  };
  nativeBuildInputs = [ autoreconfHook makeWrapper ];
  propagatedInputs = [ termux-am ];

  # https://github.com/termux/termux-tools/pull/95
  patches = [ ./termux-tools.patch ];
  postPatch = ''
    substituteInPlace scripts/termux-setup-storage.in \
      --replace @TERMUX_HOME@ /data/data/com.termux.nix/files/home/ \
      --replace @TERMUX_APP_PACKAGE@ com.termux.nix
    substituteInPlace scripts/termux-open.in \
      --replace @TERMUX_APP_PACKAGE@.app com.termux.app \
      --replace @TERMUX_APP_PACKAGE@ com.termux.nix \
      --replace 'getopt ' '${getopt}/bin/getopt '
    ${gnused}/bin/sed -i 's|^am |${termux-am}/bin/am |' scripts/*

    rm -r doc  # manpage is half misleading, pulling pandoc is not worth it
    substituteInPlace Makefile.am --replace \
      'SUBDIRS = . scripts doc mirrors motds' \
      'SUBDIRS = . scripts'
    substituteInPlace configure.ac --replace \
      'AC_CONFIG_FILES([Makefile scripts/Makefile doc/Makefile' \
      'AC_CONFIG_FILES([Makefile scripts/Makefile])'
    substituteInPlace configure.ac --replace \
      'mirrors/Makefile motds/Makefile])' ""
  '';

  outputs = [
    "out" # all the unsupported unsorted stuff
    "setup_storage" # termux-setup-storage
  ];
  postInstall = ''
    rm $out/etc/termux-login.sh
    rm $out/etc/profile.d/init-termux-properties.sh
    rm -d $out/etc/profile.d
    rm -d $out/etc

    rm $out/bin/chsh      # we offer a declarative way to change your shell
    rm $out/bin/cmd       # doesn't work because we overlay /system/bin
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

    # check that we didn't package we didn't want to
    find $out | ${gnused}/bin/sed "s|^$out|.|" | sort > effective
    echo . >> expected
    echo ./bin >> expected
    echo ./bin/termux-backup >> expected           # entirely untested
    echo ./bin/termux-open >> expected             # good candidate for fixing
    echo ./bin/termux-open-url >> expected         # good candidate for fixing
    echo ./bin/termux-reload-settings >> expected  # good candidate for fixing
    echo ./bin/termux-wake-lock >> expected        # good candidate for fixing
    echo ./bin/termux-wake-unlock >> expected      # good candidate for fixing
    echo ./bin/xdg-open >> expected                # good candidate for fixing
    echo ./share >> expected
    echo ./share/examples >> expected
    echo ./share/examples/termux >> expected
    echo ./share/examples/termux/termux.properties >> expected  # useful
    diff -u expected effective
  '';
}
