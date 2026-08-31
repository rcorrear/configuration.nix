{
  inputs,
}:
let
  inherit (inputs.nixpkgs) lib;

  mkOathkeeperMicrovmModule =
    {
      # Guest path; provision host files through extraModules, for example with microvm.shares.
      environmentFile ? null,
      extraModules ? [ ],
      hostProxyAddress ? "127.0.0.1",
      hostProxyPort ? 4455,
      sessionCheckUrl,
      upstreamUrl,
    }:
    {
      imports = [ ./module.nix ] ++ extraModules;

      networking = {
        firewall.allowedTCPPorts = [ 4455 ];
        hostName = "oathkeeper";
      };

      services.omni.oathkeeper = {
        enable = true;
        inherit environmentFile sessionCheckUrl upstreamUrl;
        api.host = "127.0.0.1";
        metrics.host = "127.0.0.1";
        openFirewall = true;
        proxy.host = "0.0.0.0";
      };

      system.stateVersion = "26.05";

      systemd.services = {
        "getty@tty1".enable = false;
        "serial-getty@ttyS0".enable = false;
      };

      microvm = {
        forwardPorts = [
          {
            host = {
              address = hostProxyAddress;
              port = hostProxyPort;
            };
            guest.port = 4455;
          }
        ];
        hypervisor = "qemu";
        interfaces = [
          {
            id = "qemu";
            mac = "02:00:00:00:00:01";
            type = "user";
          }
        ];
        mem = 512;
        shares = [ ];
        storeOnDisk = true;
        vcpu = 1;
        volumes = [ ];
        writableStoreOverlay = null;
      };
    };

  mkOathkeeperMicrovm =
    {
      system ? "x86_64-linux",
      ...
    }@args:
    if !lib.hasSuffix "-linux" system then
      throw "mkOathkeeperMicrovm requires a Linux guest system"
    else
      lib.nixosSystem {
        inherit system;
        modules = [
          inputs.microvm.nixosModules.microvm
          (mkOathkeeperMicrovmModule (removeAttrs args [ "system" ]))
        ];
      };
in
{
  inherit mkOathkeeperMicrovm mkOathkeeperMicrovmModule;
}
