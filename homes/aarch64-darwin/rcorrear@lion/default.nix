{
  config,
  pkgs,
  ...
}:
let
  p = pkgs;
in
{
  imports = [
    ../../all-platforms/rcorrear
  ];

  config = {
    home = {
      packages = [
        (p.aspellWithDicts (dicts: [ dicts.en ]))
        p.desktop-file-utils
        p.discord
        p.emacs-all-the-icons-fonts
        p.enchant
        p.exercism
        (p.flix.override { jre = pkgs.jdk23; })
        p.jdk23
        p.jetbrains.idea-community
        p.jetbrains.pycharm-community
        # p.maestral
        # p.maestral-gui
        p.metals
        p.mpg123
        p.nix-output-monitor
        p.nix-prefetch-git
        p.nixd
        p.nixfmt-rfc-style
        p.nixos-generators
        p.nodePackages.bash-language-server
        p.nodejs
        p.ntfs3g
        p.nvd
        p.moonlight-qt
        p.pipenv
        p.shellcheck
        p.shfmt
        p.sqlite
        p.unison-ucm
        p.vorbis-tools
        p.vulkan-tools
        p.zstd
      ];

      sessionPath = [
        "${config.home.homeDirectory}/Projects/go/bin"
        "${config.xdg.configHome}/emacs/bin"
      ];

      sessionVariables = {
        NH_FLAKE = "${config.home.homeDirectory}/Projects/nix/configuration.nix";
      };

      # This value determines the Home Manager release that your
      # configuration is compatible with. This helps avoid breakage
      # when a new Home Manager release introduces backwards
      # incompatible changes.
      #
      # You can update Home Manager without changing this value. See
      # the Home Manager release notes for a list of state version
      # changes in each release.
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
        };
      };

      go = {
        enable = true;
        goPath = "${config.home.homeDirectory}/Projects/go";
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

    services = {
      emacs = {
        client.enable = true;
        defaultEditor = true;
        enable = true;
        startWithUserSession = true;
      };
    };
  };
}
