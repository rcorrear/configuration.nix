{ inputs, lib, ... }:
{
  den.aspects.tailscale.nixos =
    { pkgs, ... }:
    let
      interfaces = [
        "net0"
        "net3"
        "net30"
      ];
      mkEthtoolService = ifname: {
        enable = true;
        description = "ethtool-${ifname}";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          User = "root";
          ExecStart = "${pkgs.ethtool}/bin/ethtool -K ${ifname} rx-udp-gro-forwarding on rx-gro-list off";
        };
        wantedBy = [ "multi-user.target" ];
      };
    in
    {
      imports = [
        ../../../lib/lxc-base.nix
        ../../../lib/nixos-base.nix
        inputs.home-manager.nixosModules.home-manager
        # Expects nixpkgs to expose nixos/modules/virtualisation/lxc-container.nix.
        "${inputs.nixpkgs}/nixos/modules/virtualisation/lxc-container.nix"
      ];

      boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
      };

      networking = {
        hostName = "tailscale";
        interfaces = {
          net0.useDHCP = true;
          net3.useDHCP = true;
          net30.useDHCP = true;
        };
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

      services.tailscale = {
        enable = true;
        extraUpFlags = [
          "--advertise-exit-node"
          "--advertise-routes=192.168.1.0/24,192.168.3.0/24,192.168.30.0/24,192.168.40.0/24"
          "--snat-subnet-routes=true"
        ];
        openFirewall = true;
        useRoutingFeatures = "server";
      };

      system.stateVersion = "22.05";

      systemd = {
        services = lib.listToAttrs (
          map (ifname: {
            name = "ethtool-${ifname}";
            value = mkEthtoolService ifname;
          }) interfaces
        );
        suppressedSystemUnits = [ "sys-kernel-debug.mount" ];
      };

      virtualisation.lxc.enable = true;
    };
}
