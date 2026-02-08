# Common Darwin (macOS) workstation configuration
#
# This module provides shared settings for macOS workstations including:
# - Development shells and documentation
# - Homebrew with common apps
# - Network configuration
# - Keyboard remapping (Caps Lock → Escape)
# - System defaults
#
# Note: Does not include 1Password - using AppStore version
#
{ pkgs, ... }:
{
  environment = {
    extraOutputsToInstall = [
      "doc"
      "info"
      "devdoc"
    ];
    shells = [ pkgs.fish ];
    systemPackages = [ pkgs.neovim ];
  };

  homebrew = {
    enable = true;
    casks = [
      "raycast"
    ];
    onActivation.cleanup = "zap";
  };

  networking = {
    search = [
      "home.arpa"
      "wifi.home.arpa"
    ];
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  system = {
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true;
    };
  };

}
