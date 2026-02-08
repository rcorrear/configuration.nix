# Common shell enhancement tools
#
# This module provides shared command-line tools and their configurations:
# - bat: A cat clone with syntax highlighting and Git integration
# - bottom: A cross-platform graphical process/system monitor
# - direnv: Environment variable manager with Nix integration
#
{ pkgs, ... }:
{
  programs = {
    bat = {
      enable = true;
      extraPackages = with pkgs.bat-extras; [
        batdiff
        batgrep
        batman
        batpipe
        batwatch
        prettybat
      ];
    };

    bottom = {
      enable = true;
      settings = {
        flags = {
          avg_cpu = true;
          temperature_type = "c";
        };

        colors = {
          low_battery_color = "red";
        };
      };
    };

    direnv = {
      enable = true;
      nix-direnv = {
        enable = true;
      };
    };
  };
}
