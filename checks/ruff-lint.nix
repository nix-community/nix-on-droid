{ pkgs, checkRoot }:
pkgs.runCommandLocal "ruff-lint"
{
  src = ./.;
  nativeBuildInputs = with pkgs; [ ruff ];
}
  ''
    cd ${checkRoot};
    ruff check --no-cache && mkdir $out
  ''
