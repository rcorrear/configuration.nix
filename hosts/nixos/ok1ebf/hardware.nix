{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ];

  boot = {
    extraModulePackages = with config.boot.kernelPackages; [
      it87
      zenpower
    ];

    initrd = {
      availableKernelModules = [
        "ahci"
        "nvme"
        "sd_mod"
        "usb_storage"
        "usbhid"
        "xhci_pci"
      ];

      kernelModules = [ "dm_thin_pool" ];

      supportedFilesystems = [ "zfs" ];
    };

    kernelModules = [
      "kvm-amd"
      "it87"
      "ntsync"
      "vfio"
      "vfio_iommu_type1"
      "vfio_pci"
      "vfio_virqfd"
    ];

    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };

    loader = {
      efi.canTouchEfiVariables = true;

      systemd-boot = {
        # Lanzaboote currently replaces the systemd-boot module.
        # This setting is usually set to true in configuration.nix
        # generated at installation time. So we force it to false
        # for now.
        enable = false;
        consoleMode = "max";
        edk2-uefi-shell.enable = true;
        memtest86.enable = true;
      };
    };

    supportedFilesystems = [
      "xfs"
      "zfs"
    ];

    tmp.cleanOnBoot = true;
  };

  environment.systemPackages = with pkgs; [
    hddtemp
    lm_sensors
    sbctl
    thin-provisioning-tools
  ];

  fileSystems = {
    "/" = {
      device = "rpool/safe/root/nixos";
      fsType = "zfs";
    };

    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };

    "/home" = {
      device = "rpool/safe/home";
      fsType = "zfs";
      options = [ "zfsutil" ];
    };

    "/home/rcorrear/Documents" = {
      device = "files:/rcorrear/Documents";
      fsType = "nfs4";
      options = [
        "bg"
        "noauto"
        "sec=sys"
        "soft"
        "x-systemd.automount"
        "x-systemd.idle-timeout=600"
      ];
    };

    "/home/rcorrear/Games" = {
      device = "/dev/mapper/data-games";
      fsType = "xfs";
    };

    "/home/rcorrear/Projects" = {
      device = "/dev/mapper/data-projects";
      fsType = "xfs";
    };

    "/nix/store" = {
      device = "/nix/store";

      options = [ "bind" ];
    };

    "/tmp" = {
      device = "/dev/mapper/data-tmp";
      fsType = "xfs";
      options = [
        "nodev"
        "nosuid"
        "noatime"
        "nofail"
        "x-systemd.device-timeout=10s"
      ];
    };
  };

  hardware = {
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    keyboard.uhk.enable = true;

    nvidia = {
      modesetting.enable = true;
      open = true;
      powerManagement.enable = true;
    };

    graphics = {
      enable = true;
      enable32Bit = true;
    };

    sane = {
      enable = true;
      extraBackends = [ pkgs.hplipWithPlugin ];
      openFirewall = true;
    };

    sensor = {
      hddtemp = {
        enable = true;
        drives = [ "/dev/disk/by-path/*" ];
      };
    };
  };

  # pciPassthrough = {
  #   cpuType = "amd";
  #   kvmfr = true;
  #   libvirtUsers = [ "rcorrear" ];
  #   pciIDs = "10de:2206,10de:1aef";
  # };

  swapDevices = [ ];
}
