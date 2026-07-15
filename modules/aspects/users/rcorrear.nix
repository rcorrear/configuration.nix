{ den, ... }:
{
  den.aspects.rcorrear-darwin.includes = [
    den.aspects.dev-lang
    den.aspects.dev-tools
    den.aspects.editors
    den.aspects.llm-tools
    den.aspects.rcorrear-workstation
  ];

  den.aspects.rcorrear = {
    includes = [
      den._.primary-user
      # Creates `users.users.rcorrear` (OS) and sets
      # `home.username`/`home.homeDirectory` (home-manager) for every
      # host/home this user is declared on, replacing the manual
      # boilerplate that used to live in the class configs below.
      den.batteries.define-user
      (den.batteries.user-shell "fish")
    ];

    # NixOS-specific system configuration
    nixos =
      { config, ... }:
      {
        nix.settings.trusted-users = [ "rcorrear" ];

        users.users.rcorrear = {
          description = "Ricardo Correa";
          extraGroups = [ "wheel" ];
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOtdwHE6TetQ03CFr07piiViyG2YVPfwQg3n7rONOYeo 1password"
          ];
          uid = config.den.userIds.rcorrear;
        };
      };

    # Darwin-specific system configuration
    darwin = _: {
      nix.settings.trusted-users = [ "rcorrear" ];
    };

    homeManager = {
      imports = [ ../../../homes/all-platforms/rcorrear ];
    };
  };
}
