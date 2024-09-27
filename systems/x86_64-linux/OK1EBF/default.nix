# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ lib, pkgs, ... }:
let
  hardware = import ./hardware.nix;
in
{
  imports = [ hardware ];
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
      systemPackages = with pkgs; [ neovim ];
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
      firewall.allowedTCPPorts = [ 56954 ];
      firewall.allowedUDPPorts = [ ];

      # Configure network proxy if necessary
      # proxy.default = "http://user:password@proxy:port/";
      # proxy.noProxy = "127.0.0.1,localhost,internal.domain";

      networkmanager.enable = true;
    };

    nix = {
      extraOptions = ''
        experimental-features = nix-command flakes
      '';
      settings.trusted-users = [
        "root"
        "rcorrear"
      ];
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
      mtr.enable = true;
      steam.enable = true;
      ssh.askPassword = "${pkgs.libsForQt5.ksshaskpass.out}/bin/ksshaskpass";
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

      gnome = {
        games.enable = true;
      };

      hardware.openrgb = {
        enable = true;
        motherboard = "amd";
      };

      locate = {
        enable = true;
        localuser = null;
        package = pkgs.plocate;
      };

      ollama = {
        enable = true;
        acceleration = "cuda";
      };

      openssh = {
        enable = true;
        openFirewall = true;
        settings = {
          X11Forwarding = true;
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
        enable = true; # Enable the X11 windowing system.
        desktopManager.gnome.enable = true; # Enable the GNOME Desktop Environment.
        displayManager.gdm = {
          debug = true;
          enable = true;
        };
        xkb.layout = "us"; # Configure keymap in X11
        screenSection = ''
          Option "metamodes" "2560x1440_144 +0+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}"
        '';
        videoDrivers = [ "nvidia" ];
        # windowManager = {stumpwm.enable = true;};
      };

      zfs = {
        autoScrub.enable = true;
        autoSnapshot.enable = true;
        trim.enable = true;
      };
    };

    # Enable Polkit
    security.polkit.enable = true;

    systemd = {
      services.libvirtd = {
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
      # spiceUSBRedirection.enable = true;
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
