{ inputs, ... }:
{
  den.aspects.hass.nixos =
    { pkgs, ... }:
    {
      imports = [
        ../../../lib/lxc-base.nix
        ../../../lib/nixos-base.nix
        inputs.home-manager.nixosModules.home-manager
        # Expects nixpkgs to expose nixos/modules/virtualisation/lxc-container.nix.
        "${inputs.nixpkgs}/nixos/modules/virtualisation/lxc-container.nix"
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
      };

      system.stateVersion = "22.05";

      systemd.suppressedSystemUnits = [ "sys-kernel-debug.mount" ];

      virtualisation.lxc.enable = true;
    };
}
