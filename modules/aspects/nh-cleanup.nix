{
  den.aspects.nh-cleanup = {
    includes = [ ];

    # `nh clean` only prunes profiles the invoking user can write to, so
    # both levels are needed for full coverage:
    #
    # - The `nixos` key runs as a root systemd service and is the only one
    #   able to prune root-owned system profile generations
    #   (/nix/var/nix/profiles/system). As root it covers per-user profiles
    #   on that host too, making the home-manager timer below redundant
    #   (but harmless) on NixOS.
    # - The `homeManager` key covers what NixOS-level cleanup can't reach:
    #   Darwin (nix-darwin has no system-level `programs.nh` module; the
    #   launchd agent prunes home-manager/user profiles, while darwin
    #   *system* generations are only pruned by a manual `sudo nh clean`)
    #   and standalone `homeConfigurations` activated on foreign hosts.
    nixos = {
      programs.nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 14d --keep 5";
      };
    };

    homeManager =
      { config, lib, ... }:
      {
        options.den.flakeCheckoutPath = lib.mkOption {
          type = lib.types.str;
          # Best-effort guess of where this flake is checked out, used by
          # `nh` (nix-helper) to find it. Override this per-user/per-host if
          # you clone this repo somewhere else.
          default = "${config.home.homeDirectory}/Projects/nix/configuration.nix";
          description = "Absolute path to this flake's checkout, used by `nh`.";
        };

        config.programs.nh = {
          enable = true;
          flake = config.den.flakeCheckoutPath;
          clean.enable = true;
          clean.extraArgs = "--keep-since 14d --keep 5";
        };
      };
  };
}
