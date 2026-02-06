{ inputs, ... }:
{
  den.aspects.plex.nixos =
    { ... }:
    {
      imports = [
        ../../../lib/lxc-base.nix
        ../../../lib/nixos-base.nix
        inputs.home-manager.nixosModules.home-manager
        # Expects nixpkgs to expose nixos/modules/virtualisation/lxc-container.nix.
        "${inputs.nixpkgs}/nixos/modules/virtualisation/lxc-container.nix"
      ];

      networking = {
        hostName = "plex";
        interfaces.net30.useDHCP = true;
        nftables.enable = true;
      };

      programs.nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 4d --keep 3";
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
        tailscale = {
          enable = true;
          extraUpFlags = [
            "--accept-routes"
            "--exit-node-allow-lan-access"
            "--exit-node=tailscale"
          ];
          openFirewall = true;
          useRoutingFeatures = "client";
        };
        tautulli = {
          enable = true;
          openFirewall = true;
        };
      };

      system.stateVersion = "22.05";

      systemd.suppressedSystemUnits = [ "sys-kernel-debug.mount" ];

      virtualisation.lxc.enable = true;
    };
}
