{ inputs, ... }:
{
  flake-file.inputs.devenv = {
    url = "github:cachix/devenv";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  perSystem =
    { pkgs, config, ... }:
    {
      devShells.default = inputs.devenv.lib.mkShell {
        inherit inputs pkgs;

        modules = [
          (
            { pkgs, ... }:
            {
              devenv.root =
                let
                  # builtins.getEnv "PWD" is impure; only set under `nix develop --impure`.
                  pwd = builtins.getEnv "PWD";
                in
                if pwd != "" then pwd else "/tmp/devenv-configuration.nix";

              packages = [
                pkgs.devenv
                pkgs.treefmt
                (pkgs.writeShellApplication {
                  name = "check";
                  # Deliberately not adding `pkgs.nix` to runtimeInputs: doing
                  # so shadows whatever `nix` is already on PATH (e.g.
                  # Determinate Nix) with plain upstream nixpkgs `nix`, which
                  # doesn't recognize Determinate-only settings like
                  # `eval-cores`/`lazy-trees` in /etc/nix/nix.conf and warns
                  # about them on every invocation. Relying on ambient PATH
                  # keeps this consistent with whatever Nix the user has
                  # installed system-wide.
                  text = ''
                    exec nix fmt -- --fail-on-change "$@"
                  '';
                })
              ];

              # `treefmt`'s formatters (deadnix, nixfmt, shfmt, yamllint,
              # yamlfmt) are defined once in modules/treefmt.nix. Point the
              # pre-commit hook at that same built wrapper instead of
              # re-declaring each formatter here, so `check`, `nix fmt`, and
              # this git hook all run identical checks.
              git-hooks.hooks = {
                treefmt = {
                  enable = true;
                  packageOverrides.treefmt = config.treefmt.build.wrapper;
                };
                flake-checker.enable = true;
                statix.enable = true;
                trufflehog.enable = true;
              };

            }
          )
        ];
      };
    };
}
