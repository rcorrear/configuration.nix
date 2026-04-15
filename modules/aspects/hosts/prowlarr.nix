{ den, ... }:
{
  den.aspects.prowlarr = {
    includes = [ den.aspects.media-lxc ];

    nixos =
      { ... }:
      {
        imports = [
        ];

        networking = {
          hostName = "prowlarr";
        };

        system.stateVersion = "22.05";

        services = {
          prowlarr = {
            enable = true;
            openFirewall = true;
          };
        };
      };
  };
}
