{
  pkgs,
  ...
}:
{
  imports = [
    ../../all/rcorrear.nix
  ];

  dconf = {
    enable = true;
    settings."org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = with pkgs.gnomeExtensions; [
        caffeine.extensionUuid
        gsconnect.extensionUuid
        tailscale-status.extensionUuid
        vitals.extensionUuid
      ];
    };
  };

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
      pkgs.desktop-file-utils
      pkgs.discord
      pkgs.evolution
      pkgs.firefox
      pkgs.font-awesome
      pkgs.fractal
      pkgs.ghostty
      pkgs.gnome-terminal
      pkgs.gnome-tweaks
      pkgs.gnomeExtensions.caffeine
      pkgs.gnomeExtensions.gsconnect
      pkgs.gnomeExtensions.tailscale-status
      pkgs.gnomeExtensions.vitals
      pkgs.gwe
      pkgs.keybase-gui
      pkgs.lutris
      pkgs.maestral
      pkgs.mangohud
      pkgs.moonlight-qt
      pkgs.mpg123
      pkgs.mprime
      pkgs.mtr-gui
      pkgs.nfs-utils
      pkgs.ntfs3g
      pkgs.nvtopPackages.nvidia
      pkgs.pciutils
      pkgs.piper
      pkgs.plexamp
      pkgs.prismlauncher
      pkgs.psmisc
      pkgs.remmina
      pkgs.simple-scan
      pkgs.slack
      pkgs.sshpass
      pkgs.stoat-desktop
      pkgs.sunshine
      pkgs.umu-launcher
      pkgs.usbutils
      pkgs.virtiofsd
      pkgs.vorbis-tools
      pkgs.vulkan-tools
      pkgs.wasistlos
      pkgs.wireguard-tools
      pkgs.xclip
      pkgs.xfsprogs
      pkgs.yubioath-flutter
      pkgs.zstd
    ];

    stateVersion = "21.05";
  };

  programs = {
    foot = {
      enable = true;
      server.enable = true;
      settings = {
        csd = {
          border-width = 2;
          border-color = "ff404040";
        };

        main = {
          term = "xterm-256color";
        };

        mouse = {
          hide-when-typing = "yes";
        };
      };
    };

    obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [ obs-pipewire-audio-capture ];
    };
  };

  services = {
    easyeffects.enable = true;

    kbfs = {
      enable = true;
      mountPoint = "Keybase";
    };
  };
}
