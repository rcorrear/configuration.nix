{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./ghostty.nix
    ./starship.nix
  ];

  config = {
    fonts.fontconfig.enable = true;

    home = {
      packages = [
        pkgs.any-nix-shell
        pkgs.coreutils
        pkgs.fd
        pkgs.file
        pkgs.htop
        pkgs.jq
        pkgs.neovim
        pkgs.ripgrep
        pkgs.tree
      ];

      sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

      sessionVariables = {
        PAGER = "${pkgs.less}/bin/less -FRSX";
      };

      stateVersion = lib.mkDefault "24.05";
    };

    # OpenSSH rejects the Home Manager symlink chain on Linux because the
    # resolved Nix-store file is not owned by this user or root. Keep the
    # config declarative, then materialize a private user-owned copy after
    # each Home Manager link-generation phase.
    # home.file = lib.mkIf (pkgs.stdenv.isLinux && config.programs.ssh.enable) {
    #   ".ssh/config".force = true;
    # };

    # home.activation.materializeSshConfig = lib.mkIf (pkgs.stdenv.isLinux && config.programs.ssh.enable) (
    #   lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    #     ssh_config="$HOME/.ssh/config"

    #     if [ -L "$ssh_config" ]; then
    #       ssh_config_source="$(${pkgs.coreutils}/bin/readlink -f "$ssh_config")"
    #       ${pkgs.coreutils}/bin/rm -- "$ssh_config"
    #       ${pkgs.coreutils}/bin/install -Dm600 "$ssh_config_source" "$ssh_config"
    #     fi
    #   ''
    # );

    programs = {
      dircolors = {
        enable = lib.mkDefault true;
      };

      fish = {
        enable = lib.mkDefault true;
        completions = {
          # opencode's own `opencode completion <shell>` command ignores the
          # shell argument entirely and always emits a bash-specific yargs
          # completion script (verified: `opencode completion fish` and
          # `opencode completion bash` produce byte-identical output), so it
          # cannot be sourced directly by fish. Instead, drive fish's native
          # completion system with the same `--get-yargs-completions` hook
          # that the bash script itself calls under the hood.
          opencode.body = ''
            function __opencode_yargs_complete
                set -l tokens (commandline -opc)
                set -l cur (commandline -ct)
                opencode --get-yargs-completions $tokens $cur
            end

            complete -c opencode -f -a "(__opencode_yargs_complete)"
          '';
        };
        functions = {
          # Keep sponge history focused on commands worth re-running. These
          # filters drop jj invocations whose effect is already consumed, so
          # they do not clutter history with one-off revisions or messages.
          sponge_filter_jj_message_commands = ''
            set -l jj_command $argv[1]

            if string match -rq '^jj\s+(commit|describe|desc|new|squash|ci|split|workspace\s+add)(?:\s|$)' -- $jj_command
                if string match -rq '(^|\s)(-m|--message)(?:\s|=)' -- $jj_command
                    return 0
                end
            end

            return 1
          '';
          sponge_filter_jj_revision_commands = ''
            set -l jj_command $argv[1]

            # Ignore revision-oriented jj commands while keeping bare invocations
            # like `jj new` and `jj describe` in history.
            if string match -rq '^jj(?:\s|$)' -- $jj_command
                if string match -rq '^jj\s+(abandon|arrange|backout|diffedit|duplicate|edit|interdiff|metaedit|parallelize|show|sign|simplify-parents|split|squash|unsign)\s+[^-\s][^\s]*(?:\s|$)' -- $jj_command
                    or string match -rq '^jj\s+(describe|desc|new)\s+[^-\s][^\s]*(?:\s|$)' -- $jj_command
                    or string match -rq '^jj\s+bookmark\s+(create|delete|forget|move|rename|set|track|untrack)\s+[^-\s][^\s]*(?:\s|$)' -- $jj_command
                    # Drop one-off bookmark pushes (for example: `jj git push --bookmark multiple-github-runners`).
                    or string match -rq '^jj\s+git\s+push(?:\s+[^\s]+)*\s+(?:--bookmark|-b)(?:\s+|=)[^\s]+' -- $jj_command
                    # Match only long-form revision selectors here; short flags are matched per-command below to avoid over-filtering.
                    or string match -rq '(^|\s)(--revision|--revisions|--source|--destination|--from|--to|--onto|--into|--insert-after|--insert-before)(?:\s|=)' -- $jj_command
                    # Match short revision selectors, including attached values like `-slqp` and separated forms like `-s   lqp`.
                    or string match -rq '^jj\s+(abandon|arrange|describe|desc|duplicate|edit|evolog|evolution-log|interdiff|log|metaedit|show|sign|simplify-parents|unsign)(?:\s+[^\s]+)*\s+-r(?:\s+[^\s]+|[^\s]+)' -- $jj_command
                    or string match -rq '^jj\s+diff(?:\s+[^\s]+)*\s+-(?:r|f|t)(?:\s+[^\s]+|[^\s]+)' -- $jj_command
                    or string match -rq '^jj\s+diffedit(?:\s+[^\s]+)*\s+-r(?:\s+[^\s]+|[^\s]+)' -- $jj_command
                    or string match -rq '^jj\s+new(?:\s+[^\s]+)*\s+-(?:r|b|o|A|B)(?:\s+[^\s]+|[^\s]+)' -- $jj_command
                    or string match -rq '^jj\s+split(?:\s+[^\s]+)*\s+-(?:r|A|B)(?:\s+[^\s]+|[^\s]+)' -- $jj_command
                    or string match -rq '^jj\s+squash(?:\s+[^\s]+)*\s+-(?:r|o|f|t)(?:\s+[^\s]+|[^\s]+)' -- $jj_command
                    or string match -rq '^jj\s+rebase(?:\s+[^\s]+)*(?:\s+--branch(?:\s+|=)[^\s]+|\s+-(?:r|s|d|b|o|A)(?:\s+[^\s]+|[^\s]+))' -- $jj_command
                    or string match -rq '^jj\s+restore(?:\s+[^\s]+)*\s+-c(?:\s+[^\s]+|[^\s]+)' -- $jj_command
                    or string match -rq '^jj\s+revert(?:\s+[^\s]+)*\s+-d(?:\s+[^\s]+|[^\s]+)' -- $jj_command
                    return 0
                end
            end

            return 1
          '';
          sponge_filter_jw_workspace_commands = ''
            set -l jw_command $argv[1]

            # Ignore jw commands that name throwaway workspaces.
            if string match -rq '^jw\s+(add|switch|path|remove)(?:\s+[^\s]+)*\s+[^-\s][^\s]*(?:\s|$)' -- $jw_command
                return 0
            end

            return 1
          '';
        };
        interactiveShellInit = ''
          any-nix-shell fish --info-right | source

          if not contains sponge_filter_jj_message_commands $sponge_filters
              set --append sponge_filters sponge_filter_jj_message_commands
          end

          if not contains sponge_filter_jj_revision_commands $sponge_filters
              set --append sponge_filters sponge_filter_jj_revision_commands
          end

          if not contains sponge_filter_jw_workspace_commands $sponge_filters
              set --append sponge_filters sponge_filter_jw_workspace_commands
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
          {
            name = "sponge";
            src = pkgs.fishPlugins.sponge.src;
          }
        ];
      };

      fzf = {
        enable = lib.mkDefault true;
        changeDirWidget = {
          command = "fd --type d";
          options = [ "--preview 'tree -C {} | head -200'" ];
        };
        defaultCommand = "fd --type f";
        defaultOptions = [
          "--height 40%"
          "--border"
        ];
        fileWidget = {
          command = "fd --type f";
          options = [ "--preview 'head {}'" ];
        };
        historyWidget.options = [
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
            rebase-onto = [
              "util"
              "exec"
              "--"
              "${pkgs.coreutils}/bin/env"
              "sh"
              "-c"
              "jj rebase -s \"roots(mutable() ~ ::$0)\" -o \"$0\""
            ];
            rebase-trunk = [
              "rebase"
              "-s"
              "roots(mutable() ~ ::trunk())"
              "-o"
              "trunk()"
            ];
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
          ui = {
            default-command = "status";
            diff-formatter = [
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
        enable = true;
        enableDefaultConfig = false;
        settings = {
          "*" = {
            ForwardAgent = false;
            AddKeysToAgent = "no";
            Compression = false;
            ServerAliveInterval = 0;
            ServerAliveCountMax = 3;
            HashKnownHosts = false;
            UserKnownHostsFile = "~/.ssh/known_hosts";
            ControlMaster = "no";
            ControlPath = "~/.ssh/master-%r@%n:%p";
            ControlPersist = "no";
          };
        };
      };

      starship = {
        enable = lib.mkDefault true;
      };
    };
  };
}
