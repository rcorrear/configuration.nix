{ inputs, ... }:
{
  den.aspects.files.nixos =
    { pkgs, ... }:
    {
      imports = [
        ../../../lib/lxc-base.nix
        ../../../lib/nixos-base.nix
        inputs.home-manager.nixosModules.home-manager
        # Expects nixpkgs to expose nixos/modules/virtualisation/lxc-container.nix.
        "${inputs.nixpkgs}/nixos/modules/virtualisation/lxc-container.nix"
      ];

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

      systemd.tmpfiles.rules = [
        "d /srv/files/rcorrear 0750 5000 100 -"
        "d /srv/files/elizabethfeitof 0750 5001 100 -"
      ];

      networking = {
        hostName = "files";
        firewall = {
          enable = true;
          # for NFSv3; view with `rpcinfo -p`
          allowedTCPPorts = [
            111 # rcpbind
            2049 # nfsv4
            4000 # statd
            4001 # lockd
            4002 # mountd
          ];
          allowedUDPPorts = [
            111 # rcpbind
            2049 # nfsv4
            4000 # statd
            4001 # lockd
            4002 # mountd
          ];
        };
        interfaces.net0.useDHCP = true;
        nftables.enable = true;
      };

      programs.nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 4d --keep 3";
      };

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

      system.stateVersion = "22.11";

      systemd.suppressedSystemUnits = [ "sys-kernel-debug.mount" ];

      users.users.elizabethfeitof = {
        isNormalUser = true;
        uid = 5001;
      };

      home-manager.users.rcorrear = {
        imports = [ ../../../homes/all/rcorrear.nix ];
        home.stateVersion = "22.05";
        programs.ssh.enable = true;
      };

      virtualisation.lxc.enable = true;
    };
}
