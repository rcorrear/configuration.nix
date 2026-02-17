{
  config,
  lib,
  pkgs,
  ...
}:
{
  fonts.fontconfig.enable = true;

  home = {
    packages = with pkgs; [
      any-nix-shell
      coreutils
      fd
      file
      htop
      jq
      neovim
      ripgrep
      tree
      watchman
    ];

    sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

    sessionVariables = {
      PAGER = "${pkgs.less}/bin/less -FRSX";
    };

    shellAliases = {
      jjd = "${pkgs.jujutsu}/bin/jj diff";
      jjl = "${pkgs.jujutsu}/bin/jj log";
      jjt = "${pkgs.jujutsu}/bin/jj tug";
      "jjt-" = "${pkgs.jujutsu}/bin/jj tug-";
      jjgp = "${pkgs.jujutsu}/bin/jj git push";
      jjgf = "${pkgs.jujutsu}/bin/jj git fetch";
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

        # Auto-load completions from devenv profile (for direnv-managed projects).
        # Tracks the path we added so only that path is cleaned up on directory change.
        set -g __devenv_completion_path ""
        function __devenv_update_completions --on-variable DEVENV_PROFILE
            if test -n "$__devenv_completion_path"
                set -l idx (contains -i "$__devenv_completion_path" $fish_complete_path)
                and set -e fish_complete_path[$idx]
                set -g __devenv_completion_path ""
            end
            if set -q DEVENV_PROFILE
                set -l vendor "$DEVENV_PROFILE/share/fish/vendor_completions.d"
                if test -d "$vendor"; and not contains "$vendor" $fish_complete_path
                    set -gp fish_complete_path "$vendor"
                    set -g __devenv_completion_path "$vendor"
                end
            end
        end
        if set -q DEVENV_PROFILE
            __devenv_update_completions
        end
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
        aliases = {
          tug = [
            "bookmark"
            "move"
            "--from"
            "heads(::@- & bookmarks())"
            "--to"
            "@"
          ];
          "tug-" = [
            "bookmark"
            "move"
            "--from"
            "heads(::@- & bookmarks())"
            "--to"
            "@-"
          ];
        };
        fix.tools.nixfmt = {
          command = [ "${pkgs.nixfmt}/bin/nixfmt" ];
          patterns = [ "glob:'**/*.nix'" ];
        };
        fsmonitor = {
          backend = "watchman";
          watchman.register-snapshot-trigger = true;
        };
        ui = {
          default-command = "status";
          diff.formatter = [
            "${pkgs.difftastic}/bin/difft"
            "--color=always"
            "$left"
            "$right"
          ];
        };
        user = {
          email = "r.correa.r@gmail.com";
          name = "Ricardo Correa";
        };
      };
    };

    ssh = {
      enable = lib.mkDefault true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
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
    };

    starship = {
      enable = lib.mkDefault true;
    };
  };
}
