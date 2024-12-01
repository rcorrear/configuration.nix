{
  inputs,
  pkgs,
  ...
}:
{
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
    channel.enable = false;
    settings.trusted-users = [
      "rcorrear"
    ];
  };

  security.pam.enableSudoTouchIdAuth = true;

  system = {
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true;
    };
    stateVersion = 4;
  };

  time.timeZone = "America/New_York";
}
