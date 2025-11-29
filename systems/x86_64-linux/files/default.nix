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
    environment.systemPackages = [
      pkgs.rsync
    ];

    fileSystems."/exports/rcorrear" = {
      device = "/srv/files/rcorrear";
      options = [ "bind" ];
    };

    fileSystems."/exports/elizabethfeitof" = {
      device = "/srv/files/elizabethfeitof";
      options = [ "bind" ];
    };

    networking = {
      firewall = {
        enable = true;
        # for NFSv3; view with `rpcinfo -p`
        allowedTCPPorts = [
          111
          2049
          4000
          4001
          4002
          20048
        ];
        allowedUDPPorts = [
          111
          2049
          4000
          4001
          4002
          20048
        ];
      };
      interfaces.net0.useDHCP = true;
      nftables.enable = true;
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

    # Enable samba
    services = {
      nfs = {
        server = {
          enable = true;
          exports = ''
            /exports                  192.168.0.0/16(sync,sec=sys,root_squash,rw,fsid=0,subtree_check) 100.64.0.0/10(sync,sec=sys,root_squash,rw,fsid=0,subtree_check)
            /exports/elizabethfeitof  192.168.0.0/16(sync,sec=sys,root_squash,rw,nohide,no_subtree_check) 100.64.0.0/10(sync,sec=sys,root_squash,rw,nohide,no_subtree_check)
            /exports/rcorrear         192.168.0.0/16(sync,sec=sys,root_squash,rw,nohide,no_subtree_check) 100.64.0.0/10(sync,sec=sys,root_squash,rw,nohide,no_subtree_check)
          '';
          lockdPort = 4001; # fixed port for firewall
          mountdPort = 4002; # fixed port for firewall
          statdPort = 4000; # fixed port for firewall
        };
      };

      # samba = {
      #   enable = true;
      #   openFirewall = true;
      #   settings = {
      #     workgroup = "WORKGROUP";
      #     "netbios name" = "WORKGROUP";
      #     # note: localhost is the ipv6 localhost ::1
      #     "hosts allow" = "192.168.1. 192.168.3. 127.0.0.1 localhost";
      #     "hosts deny" = "0.0.0.0/0";
      #     "guest account" = "nobody";
      #     "map to guest" = "bad user";

      #     # JumpCloud configuration. Run smbpasswd -W to initialize with JumpCloud's LDAP Bind DN password
      #     security = "domain";
      #     "server role" = "standalone server";
      #     "passdb backend" = "ldapsam:ldap://ldap.jumpcloud.com:389";
      #     "ldap suffix" = "o=5eaebf9f695ca24417c5e218,dc=jumpcloud,dc=com";
      #     "ldap user suffix" = "ou=Users";
      #     "ldap admin dn" = "uid=sa-ldap-bind-dn,ou=Users,o=5eaebf9f695ca24417c5e218,dc=jumpcloud,dc=com";
      #     "ldap ssl" = "start tls";
      #     "ldap passwd sync" = "yes";
      #   };

      #   shares = {
      #     timemachine = {
      #       "browseable" = "yes";
      #       "fruit:aapl" = "yes";
      #       "fruit:delete_empty_adfiles" = "yes";
      #       "fruit:metadata" = "stream";
      #       "fruit:model" = "MacSamba";
      #       "fruit:posix_rename" = "yes";
      #       "fruit:time machine" = "yes";
      #       "fruit:veto_appledouble" = "no";
      #       "fruit:wipe_intentionally_left_blank_rfork" = "yes";
      #       "fruit:zero_file_id" = "yes";
      #       "guest ok" = "no";
      #       "path" = "/srv/files/timemachine";
      #       "public" = "no";
      #       "valid users" = "elizabethfeitof, rcorrear";
      #       "vfs objects" = "catia fruit streams_xattr";
      #       "writeable" = "yes";
      #     };
      #   };

      #   package = pkgs.samba.override {
      #     enableLDAP = true;
      #     enableMDNS = true;
      #   };
      # };

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

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "22.11"; # Did you read the comment?

    systemd.suppressedSystemUnits = [
      "sys-kernel-debug.mount"
    ];

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users = {
      elizabethfeitof = {
        initialHashedPassword = "$y$j9T$ynqvImcDj3yp1iKM.6PMw.$gPuJrVVKHZx/kY8eIX9X4sUM99TPG.JW4x3txfiVC/8";
        isNormalUser = true;
        uid = 5001;
      };
      rcorrear = {
        extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
        initialHashedPassword = "$6$3.KQj1YrODIcMCmC$sgOeVo5PGq05qLAr3wP3I7b1ScZ58ErQoxDbQ.lcnBcw8OTZf6i1xVJjCh46Mn95F6qQ.TJU9kyv26N8okF650";
        isNormalUser = true;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOtdwHE6TetQ03CFr07piiViyG2YVPfwQg3n7rONOYeo 1password"
        ];
        shell = pkgs.fish;
        uid = 5000;
      };
    };

    virtualisation.lxc.enable = true;
  };
}
