{
  config,
  namespace,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.pciPassthrough;

  nvidia-to-vfio = pkgs.writeShellApplication {
    name = "nvidia-to-vfio";
    runtimeInputs = [ pkgs.runtimeShell ];
    text = builtins.readFile ./nvidia-to-vfio;
  };

  vfio-to-nvidia = pkgs.writeShellApplication {
    name = "vfio-to-nvidia";
    runtimeInputs = [ pkgs.runtimeShell ];
    text = builtins.readFile ./vfio-to-nvidia;
  };
in
{
  ###### interface
  options.pciPassthrough = {
    enable = mkEnableOption "PCI Passthrough";

    cpuType = mkOption {
      description = "One of `intel` or `amd`";
      default = "intel";
      type = types.str;
    };

    pciIDs = mkOption {
      description = "Comma-separated list of PCI IDs to pass-through";
      type = types.str;
    };

    libvirtUsers = mkOption {
      description = "Extra users to add to libvirtd (root is already included)";
      type = types.listOf types.str;
      default = [ ];
    };

    kvmfr = mkEnableOption "kvmfr kernel module";
  };

  ###### implementation
  config = mkIf cfg.enable {
    boot = {
      extraModprobeConfig = ''
        options kvmfr static_size_mb=128
      '';

      extraModulePackages = with config.boot.kernelPackages; [
        kvmfr
      ];

      kernelParams = [
        "${cfg.cpuType}_iommu=on"
        "vfio-pci.ids=${cfg.pciIDs}"
      ];

      # These modules are required for PCI passthrough, and must come before early modesetting stuff
      kernelModules = [
        "kvmfr"
        "vfio"
        "vfio_iommu_type1"
        "vfio_pci"
        "vfio_virqfd"
      ];

      kernel.sysctl = {
        "vm.nr_hugepages" = 16384;
        "vm.hugetlb_shm_group" = config.ids.gids.kvm;
      };
    };

    environment.systemPackages = with pkgs; [
      looking-glass-client
      nvidia-to-vfio
      vfio-to-nvidia
      (pkgs.writeScriptBin "iommu-groups" ''
        #!/usr/bin/env bash
        shopt -s nullglob
        for g in $(find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V); do
            echo "IOMMU Group ''${g##*/}:"
            for d in $g/devices/*; do
                echo -e "\t$(${pkgs.pciutils}/bin/lspci -nns ''${d##*/})"
            done;
        done;
      '')
    ];

    programs.virt-manager = {
      enable = true;
    };

    services.udev.extraRules = ''
      SUBSYSTEM=="kvmfr", OWNER="qemu-libvirtd", GROUP="kvm", MODE="0660"
    '';

    virtualisation = {
      libvirtd = {
        enable = true;
        onBoot = "ignore";
        onShutdown = "shutdown";
        qemu = {
          package = pkgs.qemu_kvm;
          ovmf.enable = true;
          runAsRoot = false;
          verbatimConfig = ''
            cgroup_device_acl = [
                "/dev/null", "/dev/full", "/dev/zero",
                "/dev/random", "/dev/urandom", "/dev/ptmx",
                "/dev/kvm", "/dev/kqemu", "/dev/rtc","/dev/hpet",
                "/dev/vfio/vfio", "/dev/kvmfr0"
            ]
          '';
        };
      };
      spiceUSBRedirection.enable = true;
    };

    users.groups.libvirtd.members = [ "root" ] ++ cfg.libvirtUsers;
    users.groups.kvm.members = [ "root" ] ++ cfg.libvirtUsers;
  };
}
