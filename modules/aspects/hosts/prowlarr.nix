{ den, ... }:
{
  den.aspects.prowlarr = {
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
          hostName = "prowlarr";
          interfaces.net30.useDHCP = true;
          search = [
            "home.arpa"
            "media.home.arpa"
          ];
        };

        services = {
          prowlarr = {
            enable = true;
            openFirewall = true;
          };
        };

        system.stateVersion = "22.05";
      };
  };
}
