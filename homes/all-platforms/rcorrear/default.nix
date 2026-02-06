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
        # inputs.zmx.packages.${pkgs.stdenv.hostPlatform.system}.default

        any-nix-shell
        coreutils
        fd
        file
        htop
        jq
        neovim
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
          # "z.*" = {
          #   controlMaster = "auto";
          #   controlPersist = "10m";
          #   hostname = "%h";
          #   proxyCommand = "sh -c 'hn=\${1#z.}; exec nc \"$hn\" %p' sh %n";
          #   extraOptions = {
          #     ConnectTimeout = "5";
          #     RemoteCommand = "zmx attach %k";
          #     RequestTTY = "yes";
          #   };
          # };
        };
      };

      starship = {
        enable = lib.mkDefault true;
      };
    };
  };
}
