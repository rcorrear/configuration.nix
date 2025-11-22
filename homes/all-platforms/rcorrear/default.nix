{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = {
    fonts.fontconfig.enable = true;

    home = {
      packages = with pkgs; [
        any-nix-shell
        coreutils
        fd
        file
        htop
        jq
        ripgrep
        tree
      ];

      sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

      sessionVariables = {
        PAGER = "${pkgs.less}/bin/less -FRSX";
      };

      shellAliases = {
        jjd = "${pkgs.jujutsu}/bin/jj diff";
        jjl = "${pkgs.jujutsu}/bin/jj log";
      };

      stateVersion = lib.mkDefault "24.05";
    };

    programs = {
      dircolors = {
        enable = lib.mkDefault true;
      };

      fish = {
        enable = lib.mkDefault true;
        interactiveShellInit = ''
          any-nix-shell fish --info-right | source
        '';
        plugins = [
          {
            name = "any-nix-shell";
            src = pkgs.fetchFromGitHub {
              owner = "haslersn";
              repo = "any-nix-shell";
              rev = "b0223ee9cd187853b44e74cd8ebd418a14651eaa";
              sha256 = "sha256-S5BNTvRinYJdgwjHH09D4T26WJmU/27vMPyYCXmHnCk=";
            };
          }
          {
            name = "000-argu";
            src = pkgs.fetchFromGitHub {
              owner = "oh-my-fish";
              repo = "plugin-argu";
              rev = "1332d5c0561f9587c956b16cf096034f67202c83";
              sha256 = "sha256-dDT0rRhkSQV/ZqhtaPnDwhaxUyjg+6VGGeH9L2SUsEY=";
            };
          }
          {
            name = "001-expand";
            src = pkgs.fetchFromGitHub {
              owner = "oh-my-fish";
              repo = "plugin-expand";
              rev = "ffb18d57506c7332ae8b7b8bc8d7f56e3a2390d2";
              sha256 = "sha256-mEgoKxoe7/88p0/5vcX27VM83wp4Cii5C3sTjwnoLJ8=";
            };
          }
          {
            name = "git";
            src = pkgs.fetchFromGitHub {
              owner = "jhillyerd";
              repo = "plugin-git";
              rev = "d6950214b6b2392d3dbb2cb670f2a5f240090038";
              sha256 = "sha256-0uEKw+7EXkf5u3p3hfthSfQO/2rr3wl35ela7P2vB0Q=";
            };
          }
        ];
      };

      fzf = {
        enable = lib.mkDefault true;
        changeDirWidgetCommand = "fd --type d";
        changeDirWidgetOptions = [ "--preview 'tree -C {} | head -200'" ];
        defaultCommand = "fd --type f";
        defaultOptions = [
          "--height 40%"
          "--border"
        ];
        fileWidgetCommand = "fd --type f";
        fileWidgetOptions = [ "--preview 'head {}'" ];
        historyWidgetOptions = [
          "--sort"
          "--exact"
        ];
      };

      git = {
        settings = {
          github.user = "rcorrear";
          pull.ff = "only";
          user = {
            email = "r.correa.r@gmail.com";
            name = "Ricardo Correa";
          };
        };
      };

      jujutsu = {
        settings = {
          user = {
            email = "r.correa.r@gmail.com";
            name = "Ricardo Correa";
          };
        };
      };

      ssh = {
        enableDefaultConfig = false;
        matchBlocks."*" = {
          forwardAgent = false;
          addKeysToAgent = "no";
          compression = false;
          serverAliveInterval = 0;
          serverAliveCountMax = 3;
          hashKnownHosts = false;
          userKnownHostsFile = "~/.ssh/known_hosts";
          controlMaster = "no";
          controlPath = "~/.ssh/master-%r@%n:%p";
          controlPersist = "no";
        };
      };

      starship = {
        enable = lib.mkDefault true;
      };

      tmux = {
        enable = lib.mkDefault true;
        extraConfig = ''
          bind P paste-buffer
          bind-key -T copy-mode-vi v send-keys -X begin-selection
          bind-key -T copy-mode-vi y send-keys -X copy-selection
          bind-key -T copy-mode-vi r send-keys -X rectangle-toggle
        '';
        keyMode = "vi";
        plugins = with pkgs; [
          tmuxPlugins.ctrlw
          tmuxPlugins.pain-control
          tmuxPlugins.tmux-fzf
          tmuxPlugins.urlview

          {
            plugin = tmuxPlugins.mode-indicator;
            extraConfig = ''
              set -g status-right '%Y-%m-%d %H:%M #{tmux_mode_indicator}'
            '';
          }
          {
            plugin = tmuxPlugins.tmux-thumbs;
            extraConfig = ''
              set -g @thumbs-key T
              set -g @thumbs-osc52 1
            '';
          }
          {
            plugin = tmuxPlugins.yank;
            extraConfig = ''
              set -g @yank_selection 'clipboard'
              set -g @yank_selection_mouse 'clipboard'
            '';
          }
        ];
        terminal = "screen-256color";
      };
    };
  };
}
