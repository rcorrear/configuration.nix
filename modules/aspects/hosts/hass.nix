{ den, ... }:
{
  den.aspects.hass = {
    includes = [
      den.aspects.lxc-host
      den.aspects.nh-cleanup
      den.aspects.tailscale-client
    ];

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [ home-assistant-cli ];

        networking = {
          firewall = {
            allowedTCPPorts = [
              21063 # HASS HomeKit
              21064 # HASS HomeKit
            ];
            allowedUDPPorts = [
              5353 # HASS HomeKit
            ];
          };
          interfaces = {
            net1.useDHCP = true;
          };
        };

        services = {
          home-assistant = {
            config = {
              automation = "!include automations.yaml";
              default_config = { };
              frontend = { };
              homeassistant = {
                name = "Home";
                temperature_unit = "C";
                time_zone = "America/New_York";
                unit_system = "metric";
              };
              http = {
                use_x_forwarded_for = true;
                trusted_proxies = [
                  "127.0.0.1"
                  "::1"
                  "100.64.0.0/10" # Tailscale CGNAT IPv4 Range
                  "fd7a:115c:a1e0::/48" # Tailscale IPv6 Range
                ];
              };
            };
            enable = true;
            extraComponents = [
              "apple_tv"
              "homekit"
              "homekit_controller"
              "ios"
              "ipp"
              "zeroconf"
            ];
            openFirewall = true;
          };
          matter-server.enable = true;
        };

        system.stateVersion = "22.05";
      };
  };
}
