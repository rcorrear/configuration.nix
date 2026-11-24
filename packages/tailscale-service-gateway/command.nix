{ pkgs, package }:
# Serve configuration and advertised Services share daemon-wide state. All
# repository-managed Serve units must cooperate on this lock, including cleanup.
"${pkgs.util-linux}/bin/flock --exclusive /run/lock/tailscale-serve.lock ${pkgs.lib.getExe package}"
