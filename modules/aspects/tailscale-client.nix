{ lib, ... }:
{
  den.aspects.tailscale-client = {
    includes = [ ];

    nixos =
      { config, ... }:
      let
        cfg = config.aspects.tailscale;
        tailscale = config.services.tailscale;
      in
      {
        options.aspects.tailscale = {
          exitNode = lib.mkOption {
            type = lib.types.str;
            default = "tailscale";
            description = "Tailscale exit node hostname";
            example = "my-exit-node";
          };
        };

        config = {
          boot.initrd.systemd.network.wait-online.enable = false;

          networking = {
            firewall = {
              enable = true;
              allowedUDPPorts = [ tailscale.port ];
              trustedInterfaces = [ tailscale.interfaceName ];
            };
            nftables.enable = true;
            search = [
              "pig-duckbill.ts.net"
            ];
          };

          services.tailscale = {
            enable = true;
            extraUpFlags = [
              "--accept-routes"
              "--exit-node-allow-lan-access"
              "--exit-node=${cfg.exitNode}"
            ];
            openFirewall = true;
            useRoutingFeatures = "client";
          };

          systemd = {
            network.wait-online.enable = false;
            services.tailscaled.serviceConfig.Environment = [ "TS_DEBUG_FIREWALL_MODE=nftables" ];
          };
        };
      };
  };
}
