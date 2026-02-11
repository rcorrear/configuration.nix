{ den, ... }:
{
  den.aspects.plex = {
    includes = [
      den.aspects.lxc-host
      den.aspects.nh-cleanup
      den.aspects.tailscale-client
    ];

    nixos =
      { ... }:
      {
        imports = [
        ];

        networking = {
          hostName = "plex";
          interfaces.net30.useDHCP = true;
          search = [
            "home.arpa"
            "media.home.arpa"
          ];
        };

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

        system.stateVersion = "22.05";
      };
  };
}
