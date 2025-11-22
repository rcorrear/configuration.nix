# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  hardware = import ./hardware.nix;
in
{
  imports = [
    hardware
    inputs.lanzaboote.nixosModules.lanzaboote
    inputs.niri-flake.nixosModules.niri
    inputs.opnix.nixosModules.default
    inputs.stylix.nixosModules.stylix
  ];

  config = {
    # Packages installed in system profile. To search, run:
    # $ nix search wget
    environment = {
      gnome.excludePackages =
        (with pkgs; [ gnome-console ])
        ++ (with pkgs; [
          epiphany
          geary
          gnome-music
        ]);
      systemPackages = with pkgs; [
        neovim
      ];
    };

    # Select internationalisation properties.
    i18n.defaultLocale = "en_US.UTF-8";

    networking = {
      bridges = {
        virbr1 = {
          interfaces = [ "enp6s0" ];
        };
      };

      hostId = "bbbd8ab0";
      hostName = "OK1EBF"; # Define your hostname.

      # Open ports in the firewall.
      firewall = {
        allowedTCPPorts = [
          25565 # Minecraft
        ];
        allowedUDPPorts = [ ];
        allowedUDPPortRanges = [
          {
            # gsconnect
            from = 1714;
            to = 1764;
          }
        ];
      };

      nftables.enable = true;

      networkmanager.enable = true;
    };

    nix = {
      extraOptions = ''
        experimental-features = nix-command flakes
      '';

      settings.trusted-users = [
        "rcorrear"
      ];
    };

    opnix = {
      # This is where you put your Service Account token in .env file format, e.g.
      # OP_SERVICE_ACCOUNT_TOKEN="{your token here}"
      # See: https://developer.1password.com/docs/service-accounts/use-with-1password-cli/#get-started
      # This file should have permissions 400 (file owner read only) or 600 (file owner read-write)
      # The systemd script will print a warning for you if it's not
      environmentFile = "/etc/opnix.env";
      # Set the systemd services that will use 1Password secrets; this makes them wait until
      # secrets are deployed before attempting to start the service.
      systemdWantedBy = [ "searx-init" ];
      # Specify the secrets you need
      secrets = {
        # The 1Password Secret Reference in here (the `op://` URI)
        # will get replaced with the actual secret at runtime
        searx = {
          source = ''
            SEARX_SECRET_KEY={{ op://Infrastructure/searx/secret key }}
          '';
          # you can also specify the UNIX file owner, group, and mode
          user = "searx";
          mode = "0600";
          # If you need to, you can even customize the path that the secret gets installed to
          path = "/run/credentials/searx.service/env";
          # You can also disable symlinking the secret into the installation destination
          symlink = false;
        };
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

      nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 4d --keep 3";
        flake = "/etc/nixos";
      };

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

    # List services that you want to enable:
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

      caddy = {
        enable = true;
        virtualHosts = {
          "openwebui.ok1ebf.home.arpa".extraConfig = ''
            reverse_proxy 127.0.0.1:8080
          '';
          "search.ok1ebf.home.arpa".extraConfig = ''
            reverse_proxy 127.0.0.1:3002
          '';
        };
      };

      cpupower-gui.enable = true;

      desktopManager.gnome.enable = true; # Enable the GNOME Desktop Environment.

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

      ollama = {
        enable = true;
        acceleration = "cuda";
        environmentVariables = {
          CUDA_DEVICE_ORDER = "FASTEST_FIRST";
        };
      };

      openssh = {
        enable = true;
        openFirewall = true;
        settings = {
          X11Forwarding = true;
        };
      };

      open-webui = {
        enable = false;
        environment = {
          CONTENT_EXTRACTION_ENGINE = "tika";
          DEVICE_TYPE = "cpu";
          DOCS_DIR = "/docs";
          ENABLE_OLLAMA_API = "True";
          ENABLE_RAG_HYBRID_SEARCH = "True";
          ENABLE_RAG_WEB_LOADER_SSL_VERIFICATION = "False";
          ENABLE_RAG_WEB_SEARCH = "True";
          OLLAMA_API_BASE_URL = "http://127.0.0.1:11434/api";
          OLLAMA_BASE_URL = "http://127.0.0.1:11434";
          PDF_EXTRACT_IMAGES = "True";
          PYDANTIC_SKIP_VALIDATING_CORE_SCHEMAS = "true";
          RAG_EMBEDDING_ENGINE = "ollama";
          RAG_EMBEDDING_MODEL = "bge-m3:latest";
          RAG_EMBEDDING_MODEL_AUTO_UPDATE = "True";
          RAG_RERANKING_MODEL = "BAAI/bge-reranker-v2-m3";
          RAG_RERANKING_MODEL_AUTO_UPDATE = "True";
          RAG_WEB_SEARCH_ENGINE = "searxng";
          RAG_WEB_SEARCH_RESULT_COUNT = "5";
          RESET_CONFIG_ON_START = "True";
          SEARXNG_QUERY_URL = "http://127.0.0.1:3002/search?q=<query>";
          TIKA_SERVER_URL = "http://127.0.0.1:9998/";
          WEBUI_AUTH = "True";
          WEBUI_NAME = "LLM @ Home";
        };
      };

      pcscd.enable = true;

      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };

      printing = {
        enable = true; # Enable CUPS to print documents.
        drivers = with pkgs; [ hplip ];
        openFirewall = true;
      };

      ratbagd.enable = true;

      resolved = {
        enable = true;
        dnssec = "false";
        dnsovertls = "opportunistic";
        domains = [ "home.arpa" ];
      };

      searx = {
        enable = true;
        environmentFile = /run/credentials/searx.service/env;
        settings = {
          server.port = 3002;
          server.secret_key = "@SEARX_SECRET_KEY@";
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

      tika = {
        enable = true;
        package = pkgs.tika;
        configFile = ./configuration/tika/tika-config.xml;
      };

      xserver = {
        enable = true; # Enable the X11 windowing system.
        xkb.layout = "us"; # Configure keymap in X11
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

      zookeeper = {
        enable = true;
        extraConf = ''
          admin.serverPort=9876
          initLimit=5
          syncLimit=2
          tickTime=2000
        '';
      };
    };

    # Enable Polkit
    security.polkit.enable = true;

    stylix = {
      enable = true;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
      fonts.monospace = {
        name = "CaskaydiaCove Nerd Font Mono";
        package = pkgs.nerd-fonts.caskaydia-cove;
      };
      image = pkgs.fetchurl {
        url = "https://images.wallpaperscraft.com/image/single/sea_clouds_horizon_1324457_3840x2160.jpg";
        sha256 = "sha256-zg/nnLtik5yHaHqd/cLl0SHkgBdTE5ouyFMPVEqzXKg=";
      };
      targets.qt.enable = false;
      polarity = "dark";
    };

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
        open-webui.requires = [
          "tika.service"
          "searx.service"
        ];
      };

      tmpfiles.rules = [ "f /dev/shm/looking-glass 0660 root kvm -" ];
    };

    # Set your time zone.
    time.timeZone = "America/New_York";

    users.users.rcorrear = {
      description = "Ricardo Correa";
      extraGroups = [
        "input"
        "kvm"
        "libvirtd"
        "render"
        "systemd-journal"
        "video"
        "wheel"
      ];
      hashedPassword = "$6$YoTVsJQVucAPr4Iw$BibgqLFotd5QbGkDPHjjMeOlmI2FzkGgW9BVz2KqfkN842Iu3MxhZzUguDlTqBxLggnWMPdj31fCW8bzpuKMq1";
      isNormalUser = true;
      shell = pkgs.fish;
      uid = 5000;
    };

    virtualisation = {
      libvirtd = {
        allowedBridges = [ "virbr1" ];
        enable = true;
        onBoot = "ignore";
        onShutdown = "shutdown";
      };
    };

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "21.05"; # Did you read the comment?
  };
}
