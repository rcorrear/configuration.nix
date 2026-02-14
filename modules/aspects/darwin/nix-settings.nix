_: {
  den.aspects.darwin-nix-settings = {
    includes = [ ];

    darwin = {
      nix = {
        enable = false;
        channel.enable = false;
      };

      system = {
        stateVersion = 4;
      };
    };
  };
}
