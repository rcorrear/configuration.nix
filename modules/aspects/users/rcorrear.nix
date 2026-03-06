{
  den,
  lib,
  ...
}:
{
  den.aspects.rcorrear = {
    includes = [ den._.primary-user ];

    # NixOS-specific system configuration
    nixos =
      { config, pkgs, ... }:
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
          uid = config.den.userIds.rcorrear;
        };
      };

    # Darwin-specific system configuration
    darwin = _: {
      users.users.rcorrear.home = "/Users/rcorrear";
    };

    homeManager =
      { pkgs, ... }:
      {
        home.username = "rcorrear";
        home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/rcorrear" else "/home/rcorrear";

        imports = [ ../../../homes/all/rcorrear.nix ];
      };
  };
}
