{ inputs, ... }:
{
  den.aspects.sonarr.nixos =
    { ... }:
    {
      imports = [
        ../../../lib/lxc-container-base.nix
        inputs.home-manager.nixosModules.home-manager
        ../../../lib/nh-cleanup.nix
        ../../../lib/tailscale-client.nix
        "${inputs.nixpkgs}/nixos/modules/virtualisation/lxc-container.nix"
      ];

      networking = {
        hostName = "sonarr";
        interfaces.net30.useDHCP = true;
        nftables.enable = true;
      };

      nixpkgs.config.permittedInsecurePackages = [
        "aspnetcore-runtime-6.0.36"
        "dotnet-sdk-6.0.428"
      ];

      home-manager.users.rcorrear = {
        imports = [ ../../../homes/all/rcorrear.nix ];
        home.stateVersion = "22.05";
        programs.ssh.enable = true;
      };

      services = {
        sonarr = {
          enable = true;
          openFirewall = true;
        };
      };

      system.stateVersion = "22.05";
    };
}
