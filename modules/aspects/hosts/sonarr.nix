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

        nixpkgs.config.permittedInsecurePackages = [
          "aspnetcore-runtime-6.0.36"
          "dotnet-sdk-6.0.428"
        ];

        home-manager.users.rcorrear = {
          imports = [ ../../../homes/all/rcorrear.nix ];
          home.stateVersion = "22.05";
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
