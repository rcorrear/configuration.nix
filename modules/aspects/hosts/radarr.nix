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

        home-manager.users.rcorrear = {
          imports = [ ../../../homes/all/rcorrear.nix ];
          home.stateVersion = "22.05";
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
