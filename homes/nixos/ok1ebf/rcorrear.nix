{ pkgs, ... }:
{
  imports = [
    ../../all/rcorrear.nix
  ];

  home = {
    keyboard = {
      options = [ "caps:escape" ];
    };

    packages = [
      # arcan
      pkgs.arcan
      pkgs.cat9
      pkgs.durden
      pkgs.pipeworld
      pkgs.prio
      pkgs.xarcan

      pkgs.rcorrear.cider-3
      pkgs.rcorrear.exiled-exchange2

      pkgs.atlauncher
      pkgs.celluloid
      pkgs.font-awesome
      pkgs.gwe
      pkgs.lutris
      pkgs.mangohud
      pkgs.moonlight-qt
      pkgs.nvtopPackages.nvidia
      pkgs.piper
      pkgs.plexamp
      pkgs.prismlauncher
      pkgs.sunshine
      pkgs.umu-launcher
      pkgs.vorbis-tools
    ];

    stateVersion = "21.05";
  };

  programs = {
    obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [ obs-pipewire-audio-capture ];
    };
  };

  services = {
    easyeffects.enable = true;
  };
}
