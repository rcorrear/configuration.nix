{
  config,
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

      (pkgs.aspellWithDicts (dicts: [ dicts.en ]))

      pkgs.atlauncher
      pkgs.beancount
      pkgs.beancount-black
      pkgs.beancount-language-server
      pkgs.celluloid
      pkgs.clang
      pkgs.cmake
      pkgs.desktop-file-utils
      pkgs.discord
      pkgs.editorconfig-checker
      pkgs.enchant
      pkgs.evolution
      pkgs.fava
      pkgs.firefox
      pkgs.font-awesome
      pkgs.fractal
      pkgs.gg-jj
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
      pkgs.msbuild
      pkgs.mtr-gui
      pkgs.multimarkdown
      pkgs.nfs-utils
      pkgs.nil
      pkgs.nix-output-monitor
      pkgs.nix-prefetch-git
      pkgs.nixd
      pkgs.nixos-generators
      pkgs.ntfs3g
      pkgs.nvd
      pkgs.nvtopPackages.nvidia
      pkgs.pciutils
      pkgs.piper
      pkgs.plexamp
      pkgs.podman
      pkgs.pre-commit
      pkgs.prismlauncher
      pkgs.psmisc
      pkgs.remmina
      pkgs.simple-scan
      pkgs.slack
      pkgs.sshpass
      pkgs.sunshine
      pkgs.uhk-agent
      pkgs.umu-launcher
      pkgs.usbutils
      pkgs.virtiofsd
      pkgs.vorbis-tools
      pkgs.vulkan-tools
      pkgs.wasistlos
      pkgs.wineWowPackages.stagingFull
      pkgs.winetricks
      pkgs.wireguard-tools
      pkgs.xclip
      pkgs.xfsprogs
      pkgs.yubioath-flutter
      pkgs.zstd
    ];

    sessionVariables = {
      NH_FLAKE = "${config.home.homeDirectory}/Projects/nix/configuration.nix";
      SSH_AUTH_SOCK = "${config.home.homeDirectory}/.1password/agent.sock";
    };

    stateVersion = "21.05";
  };

  programs = {
    difftastic = {
      enable = true;
      git.enable = true;
    };

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

    nix-index = {
      enable = true;
      enableFishIntegration = true;
    };
  };

  services = {
    easyeffects.enable = true;

    kbfs = {
      enable = true;
      mountPoint = "Keybase";
    };

    podman = {
      enable = true;
      settings = {
        policy = { };
      };
    };
  };
}
