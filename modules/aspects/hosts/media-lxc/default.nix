{ den, ... }:
{
  den.aspects.media-lxc = {
    includes = [
      den.aspects.lxc-host
      den.aspects.nh-cleanup
      den.aspects.tailscale-client
    ];

    nixos =
      { ... }:
      {
        networking = {
          interfaces.net30.useDHCP = true;
          search = [
            "media.home.arpa"
          ];
        };
      };
  };
}
