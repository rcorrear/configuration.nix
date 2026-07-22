{ den, ... }:
{
  den.aspects.prowlarr = {
    includes = [ den.aspects.media-lxc ];

    nixos =
      { ... }:
      {
        imports = [
        ];

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
