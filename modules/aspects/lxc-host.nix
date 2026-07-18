{
  den,
  inputs,
  lib,
  ...
}:
{
  den.aspects.lxc-host = {
    includes = [
      den.aspects.nh-cleanup
      den.aspects.zmx
    ];

    nixos = {
      imports = [
        "${inputs.nixpkgs}/nixos/modules/virtualisation/lxc-container.nix"
      ];

      documentation.man.cache.enable = false;
      services.openssh.enable = true;
      systemd.suppressedSystemUnits = [ "sys-kernel-debug.mount" ];
      virtualisation.lxc.enable = true;

      # LXC guests are headless, so no user D-Bus session is available for
      # Home Manager's dconf activation. This reaches every embedded Home
      # Manager user while retaining shell settings and packages.
      home-manager.sharedModules = [
        {
          dconf.settings = lib.mkForce { };
        }
      ];
    };
  };
}
