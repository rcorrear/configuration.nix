{ modulesPath, pkgs, ... }:
{
  imports = [
    (modulesPath + "/virtualisation/lxc-container.nix")
  ];

  config = {
    boot.kernel.sysctl = {
      "net.ipv6.conf.all.forwarding" = false;
      "net.ipv6.conf.net0.accept_ra" = true;
      "net.ipv6.conf.net0.accept_ra_rt_info_max_plen" = 64;
    };

    # Packages installed in system profile. To search, run:
    # $ nix search wget
    environment.systemPackages = with pkgs; [ home-assistant-cli ];

    networking = {
      # TCP 21063: HASS HomeKit
      # UDP 5353:  HASS HomeKit
      firewall.allowedTCPPorts = [
        21063
        21064
      ];
      firewall.interfaces = {
        net0.allowedUDPPorts = [ 5353 ];
        net3.allowedUDPPorts = [ 5353 ];
      };
      interfaces = {
        net0.useDHCP = true;
        net3.useDHCP = true;
      };
    };

    nix = {
      settings.trusted-users = [
        "rcorrear"
      ];
    };

    programs = {
      fish.enable = true;
      nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 4d --keep 3";
      };
    };

    # Enable home-assistant
    services = {
      # Enable home-assistant
      home-assistant = {
        config = {
          automation = "!include automations.yaml";
          default_config = { };
          frontend = { };
          homeassistant = {
            latitude = 28.172710747032205;
            longitude = -82.34285396159481;
            name = "Home";
            temperature_unit = "C";
            time_zone = "America/New_York";
            unit_system = "metric";
          };
        };
        # customComponents = [lennoxs30];
        enable = true;
        extraComponents = [
          "apple_tv"
          "homekit"
          "homekit_controller"
          "ios"
          "ipp"
          "zeroconf"
          "zha"
        ];
        # extraPackages = [lennoxs30api];
        openFirewall = true;
      };
      matter-server.enable = true;
      # Enable tailscale
      tailscale = {
        enable = true;
        extraUpFlags = [ "--accept-routes" ];
        openFirewall = true;
        useRoutingFeatures = "client";
      };
    };

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "22.05"; # Did you read the comment?

    systemd.suppressedSystemUnits = [ "sys-kernel-debug.mount" ];

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.rcorrear = {
      extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
      initialHashedPassword = "$6$3.KQj1YrODIcMCmC$sgOeVo5PGq05qLAr3wP3I7b1ScZ58ErQoxDbQ.lcnBcw8OTZf6i1xVJjCh46Mn95F6qQ.TJU9kyv26N8okF650";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOtdwHE6TetQ03CFr07piiViyG2YVPfwQg3n7rONOYeo 1password"
      ];
      shell = pkgs.fish;
      uid = 5000;
    };

    virtualisation.lxc = {
      enable = true;
    };
  };
}
