{ lib, ... }:
{
  den.aspects.rcorrear = {
    # NixOS-specific system configuration
    nixos =
      { pkgs, ... }:
      {
        nix.settings.trusted-users = [ "rcorrear" ];

        users.users.rcorrear = {
          description = "Ricardo Correa";
          extraGroups = [ "wheel" ];
          isNormalUser = true;
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOtdwHE6TetQ03CFr07piiViyG2YVPfwQg3n7rONOYeo 1password"
          ];
          shell = lib.mkOverride 900 pkgs.fish;
          uid = lib.mkDefault 5000;
        };
      };

    # Darwin-specific system configuration
    darwin = _: { };
  };
}
