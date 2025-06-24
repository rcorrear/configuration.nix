{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.stylix.darwinModules.stylix
  ];

  environment = {
    extraOutputsToInstall = [
      "doc"
      "info"
      "devdoc"
    ];
    shells = [
      pkgs.bashInteractive
      pkgs.zsh
      pkgs.fish
    ];
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
    hostName = "lion";
    knownNetworkServices = [
      "Thunderbolt Bridge"
      "USB 10/100/1000 LAN"
      "Wi-Fi"
      "iPhone USB"
    ];
    localHostName = "lion";
    search = [ "home.arpa" ];
  };

  nix = {
    enable = false;
    channel.enable = false;
    settings.trusted-users = [
      "rcorrear"
    ];
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine.yaml";
    fonts.monospace = {
      name = "CaskaydiaCove Nerd Font Mono";
      package = pkgs.nerd-fonts.caskaydia-cove;
    };
  };

  system = {
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true;
    };
    primaryUser = "rcorrear";
    stateVersion = 4;
  };

  time.timeZone = "America/New_York";
}
