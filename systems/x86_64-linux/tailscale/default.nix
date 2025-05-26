{
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [
    (modulesPath + "/virtualisation/lxc-container.nix")
  ];

  config = {
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    networking.interfaces = {
      net0.useDHCP = true;
      net3.useDHCP = true;
      net30.useDHCP = true;
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

    # Enable tailscale
    services = {
      tailscale = {
        enable = true;
        extraUpFlags = [
          "--advertise-exit-node"
          "--advertise-routes=192.168.1.0/24,192.168.3.0/24,192.168.30.0/24"
          "--snat-subnet-routes=false"
        ];
        openFirewall = true;
        useRoutingFeatures = "server";
      };
    };

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "22.05"; # Did you read the comment?

    systemd = {
      services = {
        ethtool-net0 = {
          description = "ethtool-net0";
          serviceConfig = {
            Type = "oneshot";
            User = "root";
            ExecStart = "${pkgs.ethtool}/bin/ethtool -K net0 rx-udp-gro-forwarding on rx-gro-list off";
          };
          wantedBy = [ "multi-user.target" ];
        };
        ethtool-net3 = {
          description = "ethtool-net3";
          serviceConfig = {
            Type = "oneshot";
            User = "root";
            ExecStart = "${pkgs.ethtool}/bin/ethtool -K net3 rx-udp-gro-forwarding on rx-gro-list off";
          };
          wantedBy = [ "multi-user.target" ];
        };
        ethtool-net30 = {
          description = "ethtool-net30";
          serviceConfig = {
            Type = "oneshot";
            User = "root";
            ExecStart = "${pkgs.ethtool}/bin/ethtool -K net30 rx-udp-gro-forwarding on rx-gro-list off";
          };
          wantedBy = [ "multi-user.target" ];
        };
      };
      suppressedSystemUnits = [
        "sys-kernel-debug.mount"
      ];
    };

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

    virtualisation.lxc.enable = true;
  };
}
