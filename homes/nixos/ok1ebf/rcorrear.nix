{
  config,
  pkgs,
  ...
}:
let
  local = rec {
    jdk25 = pkgs.jdk25.override { enableJavaFX = false; };
    clojure = pkgs.clojure.override { jdk = jdk25; };
  };
in
{
  imports = [
    ../../all/rcorrear.nix
    ../../modules/git-signing.nix
    ../../modules/shell-tools.nix
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
      local.clojure

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
      (pkgs.flix.override { jre = local.jdk25; })

      pkgs.atlauncher
      pkgs.beancount
      pkgs.beancount-black
      pkgs.beancount-language-server
      pkgs.celluloid
      pkgs.clang
      pkgs.cmake
      pkgs.desktop-file-utils
      pkgs.discord
      pkgs.dotnetCorePackages.sdk_9_0_1xx-bin
      pkgs.editorconfig-checker
      pkgs.enchant
      pkgs.evolution
      pkgs.exercism
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
      pkgs.jdk25
      pkgs.jetbrains.idea-oss
      pkgs.jetbrains.rider
      pkgs.keybase-gui
      pkgs.lutris
      pkgs.maestral
      pkgs.mangohud
      pkgs.metals
      pkgs.moonlight-qt
      pkgs.mpg123
      pkgs.mprime
      pkgs.msbuild
      pkgs.mtr-gui
      pkgs.multimarkdown
      pkgs.nerd-fonts.blex-mono
      pkgs.nerd-fonts.caskaydia-cove
      pkgs.nerd-fonts.iosevka-term-slab
      pkgs.nfs-utils
      pkgs.nil
      pkgs.nix-output-monitor
      pkgs.nix-prefetch-git
      pkgs.nixd
      pkgs.nixfmt
      pkgs.nixos-generators
      pkgs.nodePackages.bash-language-server
      pkgs.nodejs
      pkgs.ntfs3g
      pkgs.nvd
      pkgs.nvtopPackages.nvidia
      pkgs.pciutils
      pkgs.pijul
      pkgs.pipenv
      pkgs.piper
      pkgs.plexamp
      pkgs.podman
      pkgs.pre-commit
      pkgs.prismlauncher
      pkgs.psmisc
      pkgs.python3
      pkgs.remmina
      pkgs.shellcheck
      pkgs.shfmt
      pkgs.simple-scan
      pkgs.slack
      pkgs.sqlite
      pkgs.sshpass
      pkgs.sunshine
      pkgs.uhk-agent
      pkgs.umu-launcher
      pkgs.unison-ucm
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
      pkgs.zed
      pkgs.zed-editor
      pkgs.zstd
    ];

    sessionPath = [
      "${config.home.homeDirectory}/code/go/bin"
      "${config.xdg.configHome}/emacs/bin"
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

    emacs = {
      enable = true;
      extraPackages = epkgs: [
        epkgs.emacsql
        epkgs.vterm
      ];
      package = pkgs.emacs30.overrideAttrs (oldAttrs: {
        propagatedUserEnvPkgs = (oldAttrs.propagatedUserEnvPkgs or [ ]) ++ [
          pkgs.nodejs
          pkgs.uv
        ];
      });
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

    git = {
      enable = true;
    };

    go = {
      enable = true;
      env = {
        GOPATH = "Projects/go";
      };
    };

    jujutsu.enable = true;

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

    emacs = {
      client.enable = true;
      defaultEditor = true;
      enable = true;
      startWithUserSession = true;
    };

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
