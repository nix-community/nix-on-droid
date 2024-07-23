# Copyright (c) 2019-2022, see AUTHORS. Licensed under MIT License, see LICENSE.

{ nixpkgs, system }:

let
  pkgs = nixpkgs.legacyPackages.${system};
  pypkgs = pkgs.python311Packages;
  disablePyLints = [
    "line-too-long"
    "missing-module-docstring"
    "wrong-import-position" # import should be at top of file: we purposefully don't import click and such so that users that try to run the script directly get a friendly error
    "missing-function-docstring"
    # c'mon, it's a script
    "too-many-locals"
    "too-many-branches"
    "too-many-statements"
  ];
  deriv = pypkgs.buildPythonApplication {
    pname = "deploy";
    version = "0.0";
    src = ./.;

    inherit (pkgs) nix git rsync;

    propagatedBuildInputs = [ pypkgs.click ];

    doCheck = true;
    nativeCheckInputs = with pypkgs; [ mypy pylint black ];
    checkPhase = ''
      mypy --strict --no-color deploy.py
      PYLINTHOME="$PWD/.pylint" pylint \
        --score=n \
        --clear-cache-post-run=y \
        --disable=${pkgs.lib.concatStringsSep "," disablePyLints} \
        deploy.py
      black --check --diff deploy.py
    '';

    patchPhase = ''
      substituteInPlace deploy.py \
        --subst-var nix \
        --subst-var git \
        --subst-var rsync
    '';
  };
in
"${deriv}/bin/deploy"
