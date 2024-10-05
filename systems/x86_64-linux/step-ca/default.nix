{
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [
    (modulesPath + "/virtualisation/lxc-container.nix")
  ];

  config = {
    documentation = {
      dev.enable = false;
    };

    environment.systemPackages = with pkgs; [
      step-ca
      step-cli
    ];

    networking.interfaces.net0.useDHCP = true;

    nix = {
      settings.trusted-users = [
        "rcorrear"
      ];
    };

    programs.fish.enable = true;

    # Enable sonarr
    services =
      {
      };

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "24.05"; # Did you read the comment?

    systemd.suppressedSystemUnits = [
      "sys-kernel-debug.mount"
    ];

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.rcorrear = {
      extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
      initialHashedPassword = "$6$3.KQj1YrODIcMCmC$sgOeVo5PGq05qLAr3wP3I7b1ScZ58ErQoxDbQ.lcnBcw8OTZf6i1xVJjCh46Mn95F6qQ.TJU9kyv26N8okF650";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOtdwHE6TetQ03CFr07piiViyG2YVPfwQg3n7rONOYeo 1password"
      ];
      shell = pkgs.fish;
      uid = 5000;
    };

    virtualisation.lxc.enable = true;

    virtualisation.vmVariant = {
      # following configuration is added only when building VM with build-vm
      virtualisation = {
        cores = 4;
        graphics = true;
        memorySize = 2048; # Use 2048MiB memory.
        useBootLoader = true;
      };
    };
  };
}
