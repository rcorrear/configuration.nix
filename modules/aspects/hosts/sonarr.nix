{ den, ... }:
{
  den.aspects.sonarr = {
    includes = [ den.aspects.media-lxc ];

    nixos =
      { ... }:
      {
        imports = [
        ];

        system.stateVersion = "22.05";

        services = {
          sonarr = {
            enable = true;
            openFirewall = true;
          };
        };
      };
  };
}
