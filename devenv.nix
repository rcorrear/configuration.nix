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
    flake-checker.enable = true;
    statix.enable = true;
    trufflehog.enable = true;
    zizmor.enable = true;
  };

}
