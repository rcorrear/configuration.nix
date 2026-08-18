{ pkgs, ... }:
{
  packages = [
    pkgs.devenv
    pkgs.treefmt
  ];

  scripts.check.exec = ''
    nix fmt -- --fail-on-change "$@"
    exec prek run --all-files
  '';

  git-hooks.hooks = {
    treefmt.enable = true;
    flake-checker.enable = true;
    statix.enable = true;
    trufflehog.enable = true;
  };

}
