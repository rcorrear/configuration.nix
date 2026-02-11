{ den, ... }:
{
  den.aspects.radarr = {
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
          hostName = "radarr";
          interfaces.net30.useDHCP = true;
          search = [
            "home.arpa"
            "media.home.arpa"
          ];
        };

        services = {
          radarr = {
            enable = true;
            openFirewall = true;
          };
        };

        system.stateVersion = "22.05";
      };
  };
}
