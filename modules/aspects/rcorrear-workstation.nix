_: {
  den.aspects.rcorrear-workstation = {
    includes = [ ];

    homeManager =
      { config, pkgs, ... }:
      {
        imports = [
          ../../homes/modules/git-signing.nix
          ../../homes/modules/shell-tools.nix
        ];

        home = {
          packages = [
            pkgs.gg-jj
            pkgs.podman
            pkgs.uhk-agent
          ];

          sessionVariables = {
            NH_FLAKE = "${config.home.homeDirectory}/Projects/nix/configuration.nix";
          };
        };

        programs = {
          nix-index = {
            enable = true;
            enableFishIntegration = true;
          };
        };

        services = {
          podman = {
            enable = true;
            settings = {
              policy = { };
            };
          };
        };
      };
  };
}
