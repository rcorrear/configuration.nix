{ den, inputs, ... }:
{
  den.aspects.lxc-host = {
    includes = [ den.aspects.zmx ];

    nixos = {
      imports = [
        "${inputs.nixpkgs}/nixos/modules/virtualisation/lxc-container.nix"
      ];

      documentation.man.cache.enable = false;
      services.openssh.enable = true;
      systemd.suppressedSystemUnits = [ "sys-kernel-debug.mount" ];
      virtualisation.lxc.enable = true;
    };
  };
}
