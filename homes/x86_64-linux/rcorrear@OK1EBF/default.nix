{
  config,
  lib,
  pkgs,
  ...
}:
let
  p = pkgs;

  local = {
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
            betterthantomorrow.calva
            mechatroner.rainbow-csv
            mkhl.direnv
            visualjj.visualjj
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
  };
in
{
  imports = [
    ../../all-platforms/rcorrear
  ];

  config = {
    archetypes.programs = {
      emacs.enable = true;
    };

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
        local.vscode

        # arcan
        p.arcan
        p.cat9
        p.durden
        p.pipeworld
        p.prio
        p.xarcan

        p.rcorrear.cider-3
        p.rcorrear.exiled-exchange2

        (p.aspellWithDicts (dicts: [ dicts.en ]))
        (p.flix.override { jre = pkgs.jdk23; })

        p.aider-chat
        p.atlauncher
        p.beancount
        p.beancount-black
        p.beancount-language-server
        p.celluloid
        p.clang
        p.cmake
        p.codex
        p.desktop-file-utils
        p.discord
        p.dotnetCorePackages.sdk_9_0_1xx-bin
        p.editorconfig-checker
        p.enchant
        p.evolution
        p.exercism
        p.fava
        p.firefox
        p.font-awesome
        p.fractal
        p.gg-jj
        p.ghostty
        p.gnome-terminal
        p.gnome-tweaks
        p.gnomeExtensions.caffeine
        p.gnomeExtensions.gsconnect
        p.gnomeExtensions.tailscale-status
        p.gnomeExtensions.vitals
        p.gwe
        p.jdk23
        p.jetbrains.idea-community-bin
        p.keybase-gui
        p.lutris
        p.maestral
        p.mangohud
        p.metals
        p.moonlight-qt
        p.mpg123
        p.mprime
        p.msbuild
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
        p.opencode
        p.pciutils
        p.pijul
        p.pipenv
        p.piper
        p.plexamp
        p.podman
        p.pre-commit
        p.prismlauncher
        p.psmisc
        p.python3
        p.remmina
        p.shellcheck
        p.shfmt
        p.simple-scan
        p.slack
        p.sqlite
        p.sshpass
        p.sunshine
        p.uhk-agent
        p.umu-launcher
        p.unison-ucm
        p.usbutils
        p.virtiofsd
        p.vorbis-tools
        p.vulkan-tools
        p.whatsapp-for-linux
        p.wineWowPackages.stagingFull
        p.winetricks
        p.wireguard-tools
        p.xclip
        p.xfsprogs
        p.yubioath-flutter
        p.zed
        p.zed-editor
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
        package = (
          pkgs.emacs30.overrideAttrs (oldAttrs: {
            propagatedUserEnvPkgs = oldAttrs.propagatedUserEnvPkgs ++ [
              pkgs.nodejs
              pkgs.uv
            ];
          })
        );
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
        difftastic.enable = true;
        extraConfig = {
          "gpg \"ssh\"".program = "${pkgs._1password-gui}/bin/op-ssh-sign";
          commit.gpgsign = true;
          gpg.format = "ssh";
          safe.directory = "${config.home.homeDirectory}/Projects/nix/flake";
          user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAs0HUuftvwkh3IC+ilQ7mCjTBgXGquy0+VXoQDNPadE";
        };
      };

      go = {
        enable = true;
        env = {
          GOPATH = "${config.home.homeDirectory}/Projects/go";
        };
      };

      jujutsu = {
        enable = true;
        settings = {
          signing = {
            behavior = "own";
            backend = "ssh";
            key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAs0HUuftvwkh3IC+ilQ7mCjTBgXGquy0+VXoQDNPadE";
          };
        };
      };

      obs-studio = {
        enable = true;
        plugins = with pkgs.obs-studio-plugins; [ obs-pipewire-audio-capture ];
      };

      niri = {
        settings = {
          binds = with config.lib.niri.actions; {
            "Alt+Tab" = {
              action =
                spawn "${pkgs.glib}/bin/gdbus" "call" "--session" "--dest" "io.github.isaksamsten.Niriswitcher"
                  "--object-path"
                  "/io/github/isaksamsten/Niriswitcher"
                  "--method"
                  "io.github.isaksamsten.Niriswitcher.application";
              repeat = false;
            };
            "Alt+Shift+Tab" = {
              action =
                spawn "${pkgs.glib}/bin/gdbus" "call" "--session" "--dest" "io.github.isaksamsten.Niriswitcher"
                  "--object-path"
                  "/io/github/isaksamsten/Niriswitcher"
                  "--method"
                  "io.github.isaksamsten.Niriswitcher.application";
              repeat = false;
            };
            "Alt+Grave" = {
              action = spawn "${pkgs.niriswitcher}/bin/niriswitcherctl" "show" "--workspace";
              repeat = false;
            };
            "Alt+Shift+Grave" = {
              action = spawn "${pkgs.niriswitcher}/bin/niriswitcherctl show --workspace";
              repeat = false;
            };

            "Mod+F".action.spawn = "${pkgs.fuzzel}/bin/fuzzel";
            "Mod+T".action.spawn = "${pkgs.foot}/bin/foot";

            "Mod+Shift+E".action = quit;
            "Mod+Ctrl+Shift+E".action = quit { skip-confirmation = true; };
          };
          cursor = {
            size = 18;
          };
          input.keyboard = {
            numlock = true;
            xkb = {
              layout = "us";
              model = "pc104";
              options = "caps:escape";
            };
          };
          outputs = {
            "HDMI-A-1" = {
              enable = true;
              position = {
                x = 0;
                y = 0;
              };
            };
            "DP-3" = {
              enable = true;
              focus-at-startup = true;
              position = {
                x = 1920;
                y = 0;
              };
              variable-refresh-rate = "on-demand";
            };
          };
          spawn-at-startup = [
            { command = [ "${pkgs.mako}/bin/mako" ]; }
            { command = [ "${pkgs.niriswitcher}/bin/niriswitcher" ]; }
            { command = [ "${pkgs.waybar}/bin/waybar" ]; }
          ];
        };
      };

      niriswitcher.enable = true;

      nix-index = {
        enable = true;
        enableFishIntegration = true;
      };

      ssh = {
        enable = true;
      };

      tmux = {
        mouse = true;
        plugins = with pkgs; [
          {
            plugin = local.onePasswordTmuxPlugin;
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

      podman = {
        enable = true;
        settings = {
          policy = { };
        };
      };
    };
  };
}
