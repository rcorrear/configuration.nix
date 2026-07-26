{
  den,
  inputs,
  lib,
  ...
}:
let
  wallpaper = builtins.path {
    name = "wallhaven-yqxzqx.jpg";
    path = ../../../assets/wallhaven-yqxzqx.jpg;
  };
in
{
  flake-file.inputs.lanzaboote = {
    url = "github:nix-community/lanzaboote";
  };

  den.aspects.ok1ebf-pc = {
    includes = [ ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.gwe
          pkgs.nvtopPackages.nvidia
          pkgs.piper
        ];
      };
  };

  den.aspects."rcorrear@OK1EBF" = {
    includes = [
      den.aspects.arcan
      den.aspects.comms
      den.aspects.dev-lang
      den.aspects.dev-tools
      den.aspects.editors
      den.aspects.gaming
      den.aspects.llm-tools
      den.aspects.multimedia
      den.aspects.ok1ebf-pc
      den.aspects.plaintext-finances
      den.aspects.rcorrear-workstation
    ];

    homeManager = {
      imports = [
        ../../../homes/nixos/ok1ebf/rcorrear-niri.nix
      ];

      home.stateVersion = "21.05";

      # Keep the home-manager stylix instance (imported via
      # `den.aspects.stylix._.home`, see modules/aspects/stylix.nix) on the
      # same theme as the OS-level one below: with
      # `stylix.homeManagerIntegration.autoImport = false;`, host theme
      # overrides no longer propagate into home-manager automatically.
      aspects.stylix = {
        theme = "catppuccin-mocha";
        image = wallpaper;
      };
    };
  };

  den.aspects.OK1EBF = {
    includes = [
      den.aspects.cachix
      # den.aspects.hermes-agent
      den.aspects.nix-caches
      den.aspects.opnix
      den.aspects.stylix
    ];

    _.rcorrear.includes = [ den.aspects."rcorrear@OK1EBF" ];

    nixos =
      { pkgs, ... }:
      {
        imports = [
          ../../../hosts/nixos/ok1ebf/hardware.nix
          inputs.lanzaboote.nixosModules.lanzaboote
          inputs.niri-flake.nixosModules.niri
        ];

        environment = {
          gnome.excludePackages = [
            pkgs.gnome-console
          ]
          ++ [
            pkgs.epiphany
            pkgs.geary
            pkgs.gnome-music
          ];
          systemPackages = [
            pkgs.neovim
          ];
        };

        i18n.defaultLocale = "en_US.UTF-8";

        networking = {
          bridges = {
            virbr1 = {
              interfaces = [ "enp6s0" ];
            };
          };
          hostId = "bbbd8ab0";

          firewall = {
            allowedTCPPorts = [
              25565
            ];
            allowedUDPPortRanges = [
              {
                from = 1714;
                to = 1764;
              }
            ];
          };

          nftables.enable = true;
          networkmanager = {
            enable = true;
            settings.keyfile.unmanaged-devices = "interface-name:enp6s0;interface-name:virbr1";
          };
        };

        programs = {
          _1password = {
            enable = true;
          };

          _1password-gui = {
            enable = true;
            polkitPolicyOwners = [ "rcorrear" ];
          };

          dconf.enable = true;

          fish.enable = true;

          hyprland.enable = true;

          mtr.enable = true;

          nh.flake = "/etc/nixos";

          niri.enable = true;

          nix-ld = {
            enable = true;
            libraries = with pkgs; [
              icu
              sqlite
            ];
          };

          steam.enable = true;

          xwayland.enable = true;
        };

        services = {
          avahi = {
            enable = true;
            nssmdns4 = true;
            nssmdns6 = true;
            publish = {
              enable = true;
              addresses = true;
              domain = true;
              hinfo = true;
              userServices = true;
              workstation = true;
            };
          };

          cpupower-gui.enable = true;

          desktopManager.gnome.enable = true;

          displayManager.gdm.enable = true;

          fwupd.enable = true;

          gnome = {
            games.enable = true;
          };

          hardware.openrgb = {
            enable = true;
            motherboard = "amd";
          };

          locate = {
            enable = true;
            package = pkgs.plocate;
          };

          openssh = {
            enable = true;
            openFirewall = true;
          };

          pcscd.enable = true;

          pipewire = {
            enable = true;
            alsa.enable = true;
            alsa.support32Bit = true;
            pulse.enable = true;
          };

          printing = {
            enable = true;
            drivers = with pkgs; [ hplip ];
            openFirewall = true;
          };

          ratbagd.enable = true;

          resolved = {
            enable = true;
            settings.Resolve = {
              DNSSEC = "allow-downgrade";
              DNSOverTLS = "opportunistic";
              Domains = [
                "home.arpa"
                "media.home.arpa"
                "wifi.home.arpa"
              ];
            };
          };

          system76-scheduler = {
            enable = true;
            settings.processScheduler = {
              enable = true;
              foregroundBoost.enable = true;
              pipewireBoost.enable = true;
            };
          };

          tailscale = {
            enable = true;
            extraUpFlags = [ "--accept-routes" ];
            openFirewall = true;
            useRoutingFeatures = "client";
          };

          xserver = {
            enable = true;
            xkb.layout = "us";
            screenSection = ''
              Option "metamodes" "2560x1440_144 +0+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}"
            '';
            videoDrivers = [ "nvidia" ];
          };

          zfs = {
            autoScrub.enable = true;
            autoSnapshot.enable = true;
            trim.enable = true;
          };
        };

        security.polkit.enable = true;

        aspects.stylix = {
          theme = "catppuccin-mocha";
          image = wallpaper;
        };

        stylix.targets.qt.enable = false;

        systemd = {
          services = {
            cpupower-gui.wantedBy = lib.mkForce [ ];
            libvirtd = {
              path =
                let
                  env = pkgs.buildEnv {
                    name = "qemu-hook-env";
                    paths = with pkgs; [
                      bash
                      libvirt
                      kmod
                      systemd
                      ripgrep
                      sd
                    ];
                  };
                in
                [ env ];
            };
          };

          tmpfiles.rules = [ "f /dev/shm/looking-glass 0660 root kvm -" ];
        };

        time.timeZone = "America/New_York";

        users.users.rcorrear = {
          extraGroups = [
            "input"
            "kvm"
            "libvirtd"
            "render"
            "systemd-journal"
            "video"
            "wheel"
          ];
        };

        virtualisation = {
          libvirtd = {
            allowedBridges = [ "virbr1" ];
            enable = true;
            onBoot = "ignore";
            onShutdown = "shutdown";
          };
        };

        system.stateVersion = "21.05";
      };
  };
}
