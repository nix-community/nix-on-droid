{ pkgs, checkRoot }:
pkgs.runCommandLocal "ruff-fmt"
{
  src = ./.;
  nativeBuildInputs = with pkgs; [ ruff ];
}
  ''
    cd ${checkRoot};
    ruff format --no-cache --diff && mkdir $out
  ''
