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
  ];

  home = {
    packages = [
      local.clojure

      (pkgs.aspellWithDicts (dicts: [ dicts.en ]))
      pkgs.desktop-file-utils
      pkgs.discord
      pkgs.emacs-all-the-icons-fonts
      pkgs.enchant
      pkgs.exercism
      (pkgs.flix.override { jre = local.jdk25; })
      pkgs.jdk25
      pkgs.jetbrains.idea-community
      pkgs.jetbrains.pycharm-community
      pkgs.maestral
      pkgs.maestral-gui
      pkgs.metals
      pkgs.mpg123
      pkgs.nix-output-monitor
      pkgs.nix-prefetch-git
      pkgs.nixd
      pkgs.nixfmt
      pkgs.nixos-generators
      pkgs.nodePackages.bash-language-server
      pkgs.nodejs
      pkgs.nvd
      pkgs.moonlight-qt
      pkgs.pipenv
      pkgs.shellcheck
      pkgs.shfmt
      pkgs.sqlite
      pkgs.unison-ucm
      pkgs.vorbis-tools
      pkgs.zstd
    ];

    sessionPath = [
      "${config.home.homeDirectory}/Projects/go/bin"
      "${config.xdg.configHome}/emacs/bin"
    ];

    sessionVariables = {
      NH_FLAKE = "${config.home.homeDirectory}/Projects/nix/configuration.nix";
      SSH_AUTH_SOCK = "${config.home.homeDirectory}/.1password/agent.sock";
    };

    stateVersion = "24.11";
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
    };

    fish = {
      enable = true;
    };

    git = {
      enable = true;
      extraConfig = {
        safe.directory = "${config.home.homeDirectory}/Projects/nix/flake";
        user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAs0HUuftvwkh3IC+ilQ7mCjTBgXGquy0+VXoQDNPadE";
        commit.gpgsign = true;
        gpg.format = "ssh";
        gpg."ssh".program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      };
    };

    go = {
      enable = true;
      goPath = "Projects/go";
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

    ssh = {
      enable = true;
    };

    zsh = {
      enable = true;
      loginExtra = ''
        if [[ $(/bin/ps -o command= -p "$PPID" | /usr/bin/awk '{print $1}') != 'fish' ]]
        then
            exec ${pkgs.fish}/bin/fish -l
        fi
      '';
    };
  };

  launchd = {
    agents.emacs-daemon = {
      enable = true;
      config = {
        Label = "emacs-daemon";
        ProgramArguments = [
          "${config.programs.emacs.finalPackage}/bin/emacs"
          "--fg-daemon"
        ];
        RunAtLoad = true;
        KeepAlive = true;
      };
    };
  };
}
