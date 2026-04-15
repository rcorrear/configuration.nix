{ den, ... }:
{
  den.aspects.radarr = {
    includes = [ den.aspects.media-lxc ];

    nixos =
      { ... }:
      {
        imports = [
        ];

        networking = {
          hostName = "radarr";
        };

        system.stateVersion = "22.05";

        services = {
          radarr = {
            enable = true;
            openFirewall = true;
          };
        };
      };
  };
}
