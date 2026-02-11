{ den, ... }:
{
  den.aspects.sonarr = {
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
          hostName = "sonarr";
          interfaces.net30.useDHCP = true;
          search = [
            "home.arpa"
            "media.home.arpa"
          ];
        };

        services = {
          sonarr = {
            enable = true;
            openFirewall = true;
          };
        };

        system.stateVersion = "22.05";
      };
  };
}
