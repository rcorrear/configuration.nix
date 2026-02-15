_: {
  den.aspects.darwin-nix-settings = {
    includes = [ ];

    darwin =
      { lib, ... }:
      {
        ids.gids.nixbld = 350;
        nix = {
          enable = true;
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
