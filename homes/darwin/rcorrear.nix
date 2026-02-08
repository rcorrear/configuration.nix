{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../all/rcorrear.nix
    ../modules/git-signing.nix
    ../modules/shell-tools.nix
  ];

  home = {
    packages = [
      (pkgs.aspellWithDicts (dicts: [ dicts.en ]))
      pkgs.desktop-file-utils
      pkgs.discord
      pkgs.emacs-all-the-icons-fonts
      pkgs.enchant
      pkgs.exercism
      pkgs.jdk25
      pkgs.jetbrains.idea-community
      pkgs.jetbrains.pycharm-community
      pkgs.maestral
      pkgs.maestral-gui
      pkgs.metals
      pkgs.moonlight-qt
      pkgs.mpg123
      pkgs.nix-output-monitor
      pkgs.nix-prefetch-git
      pkgs.nixd
      pkgs.nixfmt
      pkgs.nixos-generators
      pkgs.nodePackages.bash-language-server
      pkgs.nodejs
      pkgs.nvd
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
      SSH_AUTH_SOCK = config.den.sshAgentSocket;
    };
  };

  programs = {
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

    git.enable = true;

    go = {
      enable = true;
      goPath = "Projects/go";
    };

    jujutsu.enable = true;

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
