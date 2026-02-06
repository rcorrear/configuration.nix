{
  # You also have access to your flake's inputs.
  inputs,

  # All other arguments come from NixPkgs. You can use `pkgs` to pull shells or helpers
  # programmatically or you may add the named attributes as arguments here.
  pkgs,
  ...
}:
inputs.devenv.lib.mkShell {
  inherit inputs pkgs;

  modules = [
    (
      { pkgs, ... }:
      {
        devenv.root =
          let
            pwd = builtins.getEnv "PWD";
          in
          if pwd != "" then pwd else toString inputs.self;
        packages = [
          pkgs.devenv
          pkgs.uv
        ];
        git-hooks.hooks = {
          deadnix.enable = true;
          flake-checker.enable = true;
          nixfmt.enable = true;
          shfmt.enable = true;
          statix.enable = true;
          trufflehog.enable = true;
          yamllint.enable = true;
        };
      }
    )
  ];
}
