# Nix Helper (nh) with automatic cleanup
#
# This module enables the nh (Nix Helper) program with automatic cleanup
# configured to keep recent generations.
#
# Settings:
# - Keep generations from the last 4 days
# - Keep at least 3 generations
#
{
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
  };
}
