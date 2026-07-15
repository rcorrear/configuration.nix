_: {
  den.aspects.darwin-nix-settings = {
    includes = [ ];

    darwin =
      { lib, ... }:
      {
        ids.gids.nixbld = 350;
        nix = {
          # `mkDefault` so hosts using Determinate Nix (which manages its
          # own daemon and requires `nix.enable = false;` or
          # `determinateNix.enable = true;`, see
          # modules/aspects/hosts/ferrus.nix) can override this without a
          # definition conflict.
          enable = lib.mkDefault true;
          channel.enable = false;
          settings = {
            experimental-features = lib.mkDefault [
              "nix-command"
              "flakes"
            ];
          };
        };

        system = {
          stateVersion = 4;
        };
      };
  };
}
