{ inputs, ... }:
{
  den.aspects.plex.nixos =
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
        hostName = "plex";
        interfaces.net30.useDHCP = true;
        nftables.enable = true;
      };

      home-manager.users.rcorrear = {
        imports = [ ../../../homes/all/rcorrear.nix ];
        home.stateVersion = "22.05";
        programs.ssh.enable = true;
      };

      services = {
        plex = {
          enable = true;
          openFirewall = true;
        };
        tautulli = {
          enable = true;
          openFirewall = true;
        };
      };

      system.stateVersion = "22.05";
    };
}
