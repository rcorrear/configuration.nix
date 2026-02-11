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
        imports = [
        ];

        boot.kernel.sysctl = {
          "net.ipv6.conf.all.forwarding" = false;
          "net.ipv6.conf.net0.accept_ra" = true;
          "net.ipv6.conf.net0.accept_ra_rt_info_max_plen" = 64;
        };

        environment.systemPackages = with pkgs; [ home-assistant-cli ];

        networking = {
          hostName = "hass";
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
            net0.useDHCP = true;
            net3.useDHCP = true;
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
