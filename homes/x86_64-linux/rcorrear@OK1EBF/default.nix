{
  config,
  lib,
  pkgs,
  ...
}:
let
  p = pkgs;

  onePasswordTmuxPlugin = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "plugin";
    version = "bb1bbd2acfe1b4d5dcf917f6ddf3b0f634a13362";
    src = pkgs.fetchFromGitHub {
      owner = "yardnsm";
      repo = "tmux-1password";
      rev = "bb1bbd2acfe1b4d5dcf917f6ddf3b0f634a13362";
      sha256 = "11pvwyxxkxqxyg34mcrzydz9q1wfkj1x5vx3wmy3l4p89qf2dvlk";
    };
  };

  vscode =
    with pkgs;
    (vscode-with-extensions.override {
      vscodeExtensions =
        with vscode-extensions;
        [
          asvetliakov.vscode-neovim
          mechatroner.rainbow-csv
          mkhl.direnv
        ]
        ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "vscode-deno";
            publisher = "denoland";
            version = "3.36.0";
            sha256 = "1l094qk854vgabbxbxkc8bqzwgld949sh9yvk44gl255ixqgnxy4";
          }
        ];
    });

  base = import ../../all-platforms/base;
  rcorrear = import ../../all-platforms/rcorrear;
in
{
  imports = [
    base
    rcorrear
  ];

  config = {
    home = {
      file = {
        "${config.xdg.dataHome}/Xresources-themes" = {
          source = pkgs.fetchFromGitHub {
            owner = "janoamaral";
            repo = "Xresources-themes";
            rev = "fd59f8977e2b522422e153aade456aa811914abc";
            sha256 = "11jq665iqibs9sw37fii92pyc9zld2x8ygy401dhi67i4hbp1pvi";
          };
        };
        ".Xresources" = {
          text = ''
            #include "${config.xdg.dataHome}/Xresources-themes/base16-3024-256.Xresources"

            ! Use a truetype font and size.
            xterm*faceName: FiraCode Nerd Font Mono
            xterm*faceSize: 14

            ! Allow OSC escape sequences
            xterm*disallowedWindowOps: 20,21,SetXprop
          '';
        };
        "${config.xdg.configHome}/fish/conf.d/plugin-tmux000.fish" = {
          text = ''
            set -Ux fish_tmux_autostart false
            set -Ux fish_tmux_autostart_once false
            set -Ux fish_tmux_config $HOME/.config/tmux/tmux.conf
          '';
        };
      };

      packages = [
        vscode

        # arcan
        p.arcan
        p.cat9
        p.durden
        p.pipeworld
        p.prio
        p.xarcan

        (p.aspellWithDicts (dicts: [ dicts.en ]))
        p.avahi
        p.beancount
        p.beancount-black
        p.beancount-language-server
        p.beeper
        p.bottom
        p.bruno
        p.celluloid
        p.cider
        p.cmake
        p.desktop-file-utils
        p.discord
        p.editorconfig-checker
        p.emacs-all-the-icons-fonts
        p.enchant
        p.evolution
        p.exercism
        p.factorio
        p.fava
        p.fira-code
        p.fira-code-symbols
        p.firefox
        (p.flix.override { jre = pkgs.temurin-jre-bin-21; })
        p.font-awesome
        p.fractal
        p.gitless
        p.gamescope
        p.gnome.gnome-terminal
        p.gnome.gnome-tweaks
        p.gnomeExtensions.system76-scheduler
        p.gwe
        p.jdk21
        p.jetbrains.idea-community
        p.jujutsu
        p.keybase-gui
        p.lutris
        p.maestral
        p.metals
        p.moonlight-qt
        p.mpg123
        p.mprime
        p.mullvad-vpn
        p.nfs-utils
        p.nil
        p.nix-prefetch-git
        p.nixfmt-rfc-style
        p.nixos-generators
        p.nodePackages.bash-language-server
        p.nodejs
        p.ntfs3g
        p.nvd
        p.ocamlPackages.merlin
        p.ocamlPackages.ocp-indent
        p.ocamlformat
        p.ocamlPackages.utop
        # p.open-webui
        p.pciutils
        p.pipenv
        p.plexamp
        p.psensor
        (p.nerdfonts.override {
          fonts = [
            "DroidSansMono"
            "FiraCode"
            "RobotoMono"
          ];
        })
        p.shellcheck
        p.shfmt
        p.skypeforlinux
        p.sqlite
        p.sshpass
        p.sunshine
        p.uhk-agent
        p.usbutils
        p.unison-ucm
        p.virt-manager
        p.vorbis-tools
        p.vulkan-tools
        p.whatsapp-for-linux
        p.wineWowPackages.stagingFull
        p.winetricks
        p.wireguard-tools
        p.xclip
        p.xfsprogs
        p.yubioath-flutter
        p.zstd
      ];

      sessionPath = [
        "${config.home.homeDirectory}/code/go/bin"
        "${config.xdg.configHome}/emacs/bin"
      ];

      sessionVariables = {
        BAT_THEME = "base16-256";
        SSH_AUTH_SOCK = "${config.home.homeDirectory}/.1password/agent.sock";
      };
    };

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

      emacs = {
        enable = true;
        extraPackages = epkgs: [
          epkgs.emacsql
          epkgs.emacsql-sqlite
          epkgs.vterm
        ];
        package = pkgs.emacs29;
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

            font = "RobotoMono Nerd Font Mono:size=14";
            dpi-aware = "yes";
          };

          mouse = {
            hide-when-typing = "yes";
          };
        };
      };

      git.difftastic.enable = true;

      go = {
        enable = true;
        goPath = "${config.home.homeDirectory}/Projects/go";
      };

      obs-studio = {
        enable = true;
        plugins = with pkgs.obs-studio-plugins; [ obs-pipewire-audio-capture ];
      };

      ssh = {
        enable = true;
        extraConfig = "IdentityAgent ~/.1password/agent.sock";
      };

      tmux = {
        mouse = true;
        plugins = with pkgs; [
          {
            plugin = onePasswordTmuxPlugin;
            extraConfig = ''
              set -g @1password-account 'los_correa'
              set -g @1password-key 'o'
            '';
          }

          tmuxPlugins.better-mouse-mode
        ];
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
    };
  };
}
