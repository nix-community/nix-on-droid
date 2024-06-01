# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ stdenv, fetchFromGitHub, cmake }:

let
  appPath = "/data/data/com.termux.nix/files/apps/com.termux.nix";
  socketPath = "${appPath}/termux-am/am.sock";
in
stdenv.mkDerivation rec {
  name = "termux-am";
  version = "1.5.0";
  src = fetchFromGitHub {
    owner = "termux";
    repo = "termux-am-socket";
    rev = version;
    sha256 = "sha256-6pCv2HMBRp8Hi56b43mQqnaFaI7y5DfhS9gScANwg2I=";
  };
  nativeBuildInputs = [ cmake ];
  patchPhase = ''
    # Header generation doesn't seem to work on android
    echo "#define SOCKET_PATH \"${socketPath}\"" > termux-am.h

    cat termux-am.h
    # Fix the bash link so that nix can patch it
    substituteInPlace termux-am.sh.in --replace @TERMUX_PREFIX@ ""
    head termux-am.sh.in
  '';
  postInstall = ''
    # Scripts use 'am' as an alias.
    ln -s $out/bin/termux-am $out/bin/am
  '';
}
