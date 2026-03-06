{ inputs, ... }:
{
  flake-file.inputs.devenv = {
    url = "github:cachix/devenv";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  perSystem =
    { pkgs, ... }:
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
                  name = "lint";
                  runtimeInputs = [ pkgs.nix ];
                  text = ''
                    exec nix fmt -- --fail-on-change "$@"
                  '';
                })
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
      };
    };
}
