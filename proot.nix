let
  pinnedPkgs = builtins.fetchTarball {
    name = "nixos-19.03-2019-06-14";
    url = https://github.com/nixos/nixpkgs/archive/86191b5b91322bdd88303e31d4507a684fc1b120.tar.gz;
    sha256 = "1di2s3d9fqvidix2ww3jiaq2m96xl0qn3gxh7vlw8j0z8b13z175";
  };

  buildPkgs = import pinnedPkgs {};

  overlay-jpeg-no-static = self: super: {
    libjpeg = buildPkgs.libjpeg;
  };

  crossPkgs = import pinnedPkgs {
    crossSystem = (import "${pinnedPkgs}/lib").systems.examples.aarch64-android-prebuilt;
  };

  crossStaticPkgs = import pinnedPkgs {
    crossSystem = (import "${pinnedPkgs}/lib").systems.examples.aarch64-android-prebuilt;
    crossOverlays = [
      (import "${pinnedPkgs}/pkgs/top-level/static.nix")
      overlay-jpeg-no-static
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
    version = "2019-05-05";

    src = crossStaticPkgs.fetchFromGitHub {
      repo = "proot";
      owner = "termux";
      rev = "0717de26d1394fec3acf90efdc1d172e01bc932b";
      sha256 = "1g0r3a67x94sgffz3gksyqk8r06zynfcgfdi33w6kzxnb03gbm4m";
    };

    buildInputs = [ talloc ];

    makeFlags = [ "-Csrc CFLAGS=-D__ANDROID__" ];

    installPhase = ''
      mkdir -p $out/bin
      cp src/proot $out/bin/
    '';
  };


in proot
