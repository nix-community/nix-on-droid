# Copyright (c) 2019-2024, see AUTHORS. Licensed under MIT License, see LICENSE.

{ stdenv
, fetchFromGitHub
, cmake
,
}:

let
  appPath = "/data/data/com.termux.nix/files/apps/com.termux.nix";
  socketPath = "${appPath}/termux-am/am.sock";
in
stdenv.mkDerivation (finalAttrs: {
  name = "termux-am";
  version = "1.5.0";

  src = fetchFromGitHub {
    owner = "termux";
    repo = "termux-am-socket";
    tag = finalAttrs.version;
    hash = "sha256-6pCv2HMBRp8Hi56b43mQqnaFaI7y5DfhS9gScANwg2I=";
  };

  nativeBuildInputs = [ cmake ];

  # Header generation doesn't seem to work on android
  postPatch = ''
    echo "#define SOCKET_PATH \"${socketPath}\"" > termux-am.h
  ''
  # Fix the bash link so that nix can patch it + path to termux-am-socket
  + ''
    substituteInPlace termux-am.sh.in \
      --replace-fail "@TERMUX_PREFIX@/bin/bash" "/bin/bash" \
      --replace-fail 'termux-am-socket "$am_command_string"' "$out/bin/termux-am-socket \"\$am_command_string\""
  '';

  # Scripts use 'am' as an alias.
  postInstall = ''
    ln --symbolic $out/bin/termux-am $out/bin/am
  '';
})
