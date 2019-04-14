let
  pinnedPkgs = builtins.fetchTarball {
    name = "nixos-unstable-2019-04-14";
    url = https://github.com/nixos/nixpkgs/archive/acbdaa569f4ee387386ebe1b9e60b9f95b4ab21b.tar.gz;
    sha256 = "0xzyghyxk3hwhicgdbi8yv8b8ijy1rgdsj5wb26y5j322v96zlpz";
  };

  overlay-openjdk8-linux5-fix = self: super: {
    openjdk8 = super.openjdk8.overrideAttrs (oa: {
      DISABLE_HOTSPOT_OS_VERSION_CHECK = "true";
    });
  };

  overlay-jpeg-no-static = self: super: {
    libjpeg = buildPkgs.libjpeg;
  };

  buildPkgs = import pinnedPkgs {
    overlays = [
      overlay-openjdk8-linux5-fix
    ];
  };

  crossPkgs = import pinnedPkgs {
    crossSystem = (import "${pinnedPkgs}/lib").systems.examples.aarch64-android-prebuilt;
    overlays = [
      overlay-openjdk8-linux5-fix
    ];
  };

  crossStaticPkgs = import pinnedPkgs {
    crossSystem = (import "${pinnedPkgs}/lib").systems.examples.aarch64-android-prebuilt;
    overlays = [
      overlay-openjdk8-linux5-fix
    ];
    crossOverlays = [
      (import "${pinnedPkgs}/pkgs/top-level/static.nix")
      overlay-jpeg-no-static
      overlay-openjdk8-linux5-fix
    ];
  };


  talloc = crossPkgs.stdenv.mkDerivation rec {
    name = "talloc-2.1.14";

    src = crossPkgs.fetchurl {
      url = "mirror://samba/talloc/${name}.tar.gz";
      sha256 = "1kk76dyav41ip7ddbbf04yfydb4jvywzi2ps0z2vla56aqkn11di";
    };

    depsBuildBuild = [ buildPkgs.python2 buildPkgs.zlib ];

    buildDeps = [ crossPkgs.zlib ];

    configurePhase = ''
      substituteInPlace buildtools/bin/waf \
          --replace "/usr/bin/env python" "${buildPkgs.python2}/bin/python"
      ./configure --prefix=$out \
          --disable-rpath \
          --disable-python \
          --cross-compile \
          --cross-answers=cross-answers.txt
    '';

    buildPhase = ''
      make
    '';

    installPhase = ''
      mkdir -p $out/lib
      make install
      ${crossPkgs.stdenv.cc.targetPrefix}ar q $out/lib/libtalloc.a bin/default/talloc_[0-9]*.o
    '';

    fixupPhase = "";

    prePatch = ''
      cat <<EOF > cross-answers.txt
      Checking uname sysname type: "Linux"
      Checking uname machine type: "dontcare"
      Checking uname release type: "dontcare"
      Checking uname version type: "dontcare"
      Checking simple C program: OK
      building library support: OK
      Checking for large file support: OK
      Checking for -D_FILE_OFFSET_BITS=64: OK
      Checking for WORDS_BIGENDIAN: OK
      Checking for C99 vsnprintf: OK
      Checking for HAVE_SECURE_MKSTEMP: OK
      rpath library support: OK
      -Wl,--version-script support: FAIL
      Checking correct behavior of strtoll: OK
      Checking correct behavior of strptime: OK
      Checking for HAVE_IFACE_GETIFADDRS: OK
      Checking for HAVE_IFACE_IFCONF: OK
      Checking for HAVE_IFACE_IFREQ: OK
      Checking getconf LFS_CFLAGS: OK
      Checking for large file support without additional flags: OK
      Checking for working strptime: OK
      Checking for HAVE_SHARED_MMAP: OK
      Checking for HAVE_MREMAP: OK
      Checking for HAVE_INCOHERENT_MMAP: OK
      Checking getconf large file support flags work: OK
      EOF
    '';
  };


  proot = crossStaticPkgs.stdenv.mkDerivation rec {
    name = "proot-termux-${version}";
    version = "2019-03-19";

    src = crossStaticPkgs.fetchFromGitHub {
      repo = "proot";
      owner = "termux";
      rev = "2a78bab91d01c723ecb7ce08069a096f6ff654c5";
      sha256 = "1091si4i07349y7x7sx1r904gg3c9a3m39xkv24fakjlirpi3lpy";
    };

    buildInputs = [ talloc ];

    makeFlags = [ "-Csrc CFLAGS=-D__ANDROID__" ];

    installPhase = ''
      mkdir -p $out/bin
      cp src/proot $out/bin/
    '';
  };


in proot
