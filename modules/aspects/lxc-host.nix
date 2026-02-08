{ inputs, ... }:
{
  den.aspects.lxc-host = {
    includes = [ ];

    nixos = {
      imports = [
        "${inputs.nixpkgs}/nixos/modules/virtualisation/lxc-container.nix"
      ];

      documentation.man.generateCaches = false;
      services.openssh.enable = true;
      systemd.suppressedSystemUnits = [ "sys-kernel-debug.mount" ];
      virtualisation.lxc.enable = true;
    };
  };
}
