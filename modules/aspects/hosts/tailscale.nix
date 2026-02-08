{
  den,
  lib,
  ...
}:
{
  den.aspects.tailscale = {
    includes = [
      den.aspects.lxc-host
      den.aspects.nh-cleanup
    ];

    nixos =
      { pkgs, ... }:
      let
        interfaces = [
          "net0"
          "net3"
          "net30"
        ];
        dhcpInterfaces = builtins.listToAttrs (
          map (ifname: {
            name = ifname;
            value = {
              useDHCP = true;
            };
          }) interfaces
        );
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
        ];

        boot.kernel.sysctl = {
          "net.ipv4.ip_forward" = 1;
          "net.ipv6.conf.all.forwarding" = 1;
        };

        home-manager.users.rcorrear = {
          imports = [ ../../../homes/all/rcorrear.nix ];
          home.stateVersion = "22.05";
        };

        networking = {
          hostName = "tailscale";
          interfaces = dhcpInterfaces;
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

        systemd.services = lib.listToAttrs (
          map (ifname: {
            name = "ethtool-${ifname}";
            value = mkEthtoolService ifname;
          }) interfaces
        );
      };
  };
}
