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
              rev = "ea04f9bd639f175002127ad1b5715bce3d4bd9c5";
              sha256 = "0q27rhjhh7k0qgcdcfm8ly5za6wm4rckh633d0sjz87faffkp90k";
            };
          }
          {
            name = "000-argu";
            src = pkgs.fetchFromGitHub {
              owner = "oh-my-fish";
              repo = "plugin-argu";
              rev = "1332d5c0561f9587c956b16cf096034f67202c83";
              sha256 = "0imhjij2zzg1353abyz0519v25n2qgwnhvd8crzhajb432nz8d3l";
            };
          }
          {
            name = "001-expand";
            src = pkgs.fetchFromGitHub {
              owner = "oh-my-fish";
              repo = "plugin-expand";
              rev = "ffb18d57506c7332ae8b7b8bc8d7f56e3a2390d2";
              sha256 = "17rcx04qy4vv1fwjh2kq1bgkqlzdyv2vvyaglwygzvqy38mjhj4q";
            };
          }
          {
            name = "marlin";
            src = pkgs.fetchFromGitHub {
              owner = "oh-my-fish";
              repo = "marlin";
              rev = "c58a6913c37577d20fab2fcc9c5d8d28d24173ef";
              sha256 = "1vczr0jar2wvcqiwyzcaqs9j0132x54s3qffj1b4gr2hv6p4wv4f";
            };
          }
          {
            name = "git";
            src = pkgs.fetchFromGitHub {
              owner = "jhillyerd";
              repo = "plugin-git";
              rev = "cfefe203424dcc39d57d6d8885709503b97ce6f9";
              sha256 = "0mzrpr56j2gn5rwgb24byggklda355g5q7g9csv7mqjfvd6mwp8c";
              # date = "2021-07-06T09:14:51-07:00";
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
        enable = lib.mkDefault true;
        userEmail = "r.correa.r@gmail.com";
        userName = "Ricardo Correa";
        extraConfig = {
          github.user = "rcorrear";
          pull.ff = "only";
        };
      };

      jujutsu = {
        enable = lib.mkDefault true;
        settings = {
          ui = {
            diff.tool = "${pkgs.difftastic}/bin/difft --color=always $left $right";
          };
          user = {
            email = "r.correa.r@gmail.com";
            name = "Ricardo Correa";
          };
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
