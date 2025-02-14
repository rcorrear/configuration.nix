{
  config,
  inputs,
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
in
{
  config = {
    dconf = {
      enable = true;
      settings."org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = with pkgs.gnomeExtensions; [
          caffeine.extensionUuid
          gsconnect.extensionUuid
          vitals.extensionUuid
        ];
      };
    };

    home = {
      file = {
        "${config.xdg.configHome}/fish/conf.d/plugin-tmux000.fish" = {
          text = ''
            set -Ux fish_tmux_autostart false
            set -Ux fish_tmux_autostart_once false
            set -Ux fish_tmux_config $HOME/.config/tmux/tmux.conf
          '';
        };
      };

      keyboard = {
        options = [ "caps:escape" ];
      };

      packages = [
        vscode

        inputs.ghostty.packages.x86_64-linux.default

        # arcan
        p.arcan
        p.cat9
        p.durden
        p.pipeworld
        p.prio
        #p.xarcan

        p.rcorrear.exiled-exchange2

        (p.aspellWithDicts (dicts: [ dicts.en ]))
        p.beancount
        p.beancount-black
        p.beancount-language-server
        p.celluloid
        p.cider
        p.cmake
        p.desktop-file-utils
        p.discord
        p.editorconfig-checker
        p.enchant
        p.evolution
        p.exercism
        p.fava
        p.firefox
        (p.flix.override { jre = pkgs.jdk23; })
        p.font-awesome
        p.fractal
        p.gnome-terminal
        p.gnome-tweaks
        p.gnomeExtensions.caffeine
        p.gnomeExtensions.gsconnect
        p.gnomeExtensions.vitals
        p.gwe
        p.jdk23
        #p.jetbrains.idea-community
        #p.jetbrains.pycharm-community
        p.keybase-gui
        p.lutris
        p.maestral
        p.mangohud
        p.metals
        p.moonlight-qt
        p.mpg123
        p.mprime
        p.mtr-gui
        p.nerd-fonts.blex-mono
        p.nerd-fonts.iosevka-term-slab
        p.nfs-utils
        p.nil
        p.nix-output-monitor
        p.nix-prefetch-git
        p.nixd
        p.nixfmt-rfc-style
        p.nixos-generators
        p.nodePackages.bash-language-server
        p.nodejs
        p.ntfs3g
        p.nvd
        p.nvtopPackages.nvidia
        p.open-webui
        p.pciutils
        p.pipenv
        p.piper
        p.plexamp
        p.psmisc
        p.remmina
        p.shellcheck
        p.shfmt
        p.simple-scan
        p.skypeforlinux
        p.sqlite
        p.sshpass
        p.sunshine
        p.uhk-agent
        p.usbutils
        p.unison-ucm
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
        FLAKE = /etc/nixos;
        SSH_AUTH_SOCK = "${config.home.homeDirectory}/.1password/agent.sock";
      };

      # This value determines the Home Manager release that your
      # configuration is compatible with. This helps avoid breakage
      # when a new Home Manager release introduces backwards
      # incompatible changes.
      #
      # You can update Home Manager without changing this value. See
      # the Home Manager release notes for a list of state version
      # changes in each release.
      stateVersion = "21.05";
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
          };

          mouse = {
            hide-when-typing = "yes";
          };
        };
      };

      git = {
        difftastic.enable = true;
        extraConfig = {
          "gpg \"ssh\"".program = "${pkgs._1password-gui}/bin/op-ssh-sign";
          commit.gpgsign = true;
          gpg.format = "ssh";
          safe.directory = "${config.home.homeDirectory}/Projects/nix/flake";
          user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKa59A0LGSduyaIk+rKKImRNoeJBTQV9pvvUNJJqg6cC";
        };
      };

      go = {
        enable = true;
        goPath = "${config.home.homeDirectory}/Projects/go";
      };

      jujutsu = {
        ediff = true;
      };

      obs-studio = {
        enable = true;
        plugins = with pkgs.obs-studio-plugins; [ obs-pipewire-audio-capture ];
      };

      ssh = {
        enable = true;
        extraConfig = "IdentityAgent ~/.1password/agent.sock";
      };

      thefuck = {
        enable = true;
        enableInstantMode = true;
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
