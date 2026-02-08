# Common LXC container base configuration
#
# This module provides the base configuration for all LXC containers including:
# - Standard imports (lxc-base, nixos-base, home-manager)
# - LXC virtualisation enablement
# - Systemd suppressed units for LXC compatibility
#
# Note: Each LXC host must also import the lxc-container.nix module separately
# in its own imports list, as it requires top-level NixOS module context.
#
# Each container should import this and then add container-specific configuration.
#
_: {
  imports = [
    ./lxc-base.nix
    ./nixos-base.nix
  ];

  systemd.suppressedSystemUnits = [ "sys-kernel-debug.mount" ];

  virtualisation.lxc.enable = true;
}
