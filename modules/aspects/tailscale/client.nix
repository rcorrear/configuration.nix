{ lib, ... }:
{
  den.aspects.tailscale-client = {
    includes = [ ];

    nixos =
      { config, ... }:
      let
        cfg = config.aspects.tailscale;
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

        config.services.tailscale = {
          enable = true;
          extraUpFlags = [
            "--accept-routes"
            "--exit-node-allow-lan-access"
            "--exit-node=${cfg.exitNode}"
          ];
          openFirewall = true;
          useRoutingFeatures = "client";
        };
      };
  };
}
