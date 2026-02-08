# Tailscale client configuration with exit-node support
#
# This module provides a common Tailscale configuration for clients that:
# - Accept routes from the Tailscale network
# - Use a designated exit node with LAN access
# - Open the firewall for Tailscale
# - Enable routing features for the client
#
# Options:
#   aspects.tailscale.exitNode - Exit node hostname (default: "tailscale")
#
{ config, lib, ... }:
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
}
