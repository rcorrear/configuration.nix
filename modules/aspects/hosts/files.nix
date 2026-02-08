{ den, ... }:
{
  den.aspects.files = {
    includes = [
      den.aspects.lxc-host
      den.aspects.nh-cleanup
      den.aspects.tailscale-client
    ];

    nixos =
      { config, pkgs, ... }:
      {
        imports = [
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
          "d /srv/files/rcorrear 0750 ${toString config.den.userIds.rcorrear} 100 -"
          "d /srv/files/elizabethfeitof 0750 ${toString config.den.userIds.elizabethfeitof} 100 -"
        ];

        networking = {
          hostName = "files";
          firewall = {
            enable = true;
            # for NFSv3; view with `rpcinfo -p`
            allowedTCPPorts = [
              111 # rpcbind
              2049 # nfsv4
              4000 # statd
              4001 # lockd
              4002 # mountd
            ];
            allowedUDPPorts = [
              111 # rpcbind
              2049 # nfsv4
              4000 # statd
              4001 # lockd
              4002 # mountd
            ];
          };
          interfaces.net0.useDHCP = true;
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
        };

        system.stateVersion = "22.11";

        users.users.elizabethfeitof = {
          isNormalUser = true;
          uid = config.den.userIds.elizabethfeitof;
        };

        home-manager.users.rcorrear = {
          imports = [ ../../../homes/all/rcorrear.nix ];
          home.stateVersion = "22.05";
        };

      };
  };
}
