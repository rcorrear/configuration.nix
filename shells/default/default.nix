{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # You also have access to your flake's inputs.
  inputs,

  # All other arguments come from NixPkgs. You can use `pkgs` to pull shells or helpers
  # programmatically or you may add the named attributes as arguments here.
  pkgs,
  mkShell,
  ...
}:
inputs.devenv.lib.mkShell {
  inherit inputs pkgs;

  modules = [
    (
      { pkgs, ... }:
      {
        packages = [
          pkgs.devenv
        ];
        git-hooks.hooks = {
          deadnix.enable = true;
          flake-checker.enable = true;
          nixfmt-rfc-style.enable = true;
          shfmt.enable = true;
          statix.enable = true;
          trufflehog.enable = true;
          yamllint.enable = true;
        };
      }
    )
  ];
}
