_: {
  den.aspects.rcorrear-workstation = {
    includes = [ ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        linuxDesktopPackages = [
          pkgs.desktop-file-utils
          pkgs.evolution
          pkgs.firefox
          pkgs.ghostty
          pkgs.gnome-terminal
          pkgs.gnome-tweaks
          pkgs.gnomeExtensions.caffeine
          pkgs.gnomeExtensions.gsconnect
          pkgs.gnomeExtensions.tailscale-status
          pkgs.gnomeExtensions.vitals
          pkgs.google-chrome
          pkgs.maestral
          pkgs.simple-scan
          pkgs.uhk-agent
          pkgs.yubioath-flutter
        ];

        linuxWorkstationPackages = [
          pkgs.mpg123
          pkgs.mprime
          pkgs.nfs-utils
          pkgs.pciutils
          pkgs.psmisc
          pkgs.remmina
          pkgs.usbutils
          pkgs.vulkan-tools
          pkgs.wireguard-tools
          pkgs.xclip
          pkgs.xfsprogs
          pkgs.zstd
        ];
      in
      {
        imports = [
          ../../homes/modules/git-signing.nix
          ../../homes/modules/shell-tools.nix
        ];

        dconf = lib.mkIf pkgs.stdenv.isLinux {
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
          packages = [
            (pkgs.aspellWithDicts (dicts: [
              dicts.en
              dicts.en-computers
            ]))

            pkgs.font-awesome
            pkgs.mtr-gui
            pkgs.nix-output-monitor
            pkgs.nix-prefetch-git
            pkgs.nixd
            pkgs.nixos-generators
            pkgs.ntfs3g
            pkgs.nvd
            pkgs.obsidian
            pkgs.podman-compose
            pkgs.symbola
            pkgs.yt-dlp
          ]
          ++ lib.optionals pkgs.stdenv.isLinux linuxDesktopPackages
          ++ lib.optionals pkgs.stdenv.isLinux linuxWorkstationPackages
          ++ lib.optionals pkgs.stdenv.isDarwin [ pkgs.ghostty-bin ];

          sessionVariables = {
            NH_FLAKE = "${config.home.homeDirectory}/Projects/nix/configuration.nix";
          };
        };

        programs = {
          direnv = {
            enable = true;
            nix-direnv = {
              enable = true;
            };
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

          nix-index = {
            enable = true;
            enableFishIntegration = true;
          };

          foot = lib.mkIf pkgs.stdenv.isLinux {
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

          ssh.enable = true;
        };

        services = lib.mkMerge [
          {
            podman = {
              enable = true;
              settings = {
                policy = { };
              };
            };
          }

          (lib.mkIf pkgs.stdenv.isLinux {
            dropbox.enable = true;
          })
        ];
      };
  };
}
