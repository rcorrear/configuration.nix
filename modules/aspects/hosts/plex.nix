{ den, ... }:
{
  den.aspects.plex = {
    includes = [ den.aspects.media-lxc ];

    nixos =
      { ... }:
      {
        imports = [
        ];

        networking = {
          hostName = "plex";
        };

        system.stateVersion = "22.05";

        services = {
          plex = {
            enable = true;
            openFirewall = true;
          };
          tautulli = {
            enable = true;
            openFirewall = true;
          };
        };
      };
  };
}
