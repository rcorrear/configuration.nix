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
      # Home-manager theming for every `homeManager`-class target of this
      # user: the embedded instances on each host *and* the standalone
      # `homeConfigurations."rcorrear@<host>"` entities (host-level aspect
      # includes don't reach either — see modules/aspects/stylix.nix). Only
      # the `provides.home` sub-aspect is included, so the stylix OS
      # classes don't get dragged onto every (headless) host this user is
      # declared on.
      den.aspects.stylix._.home
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

    homeManager = {
      imports = [ ../../../homes/all-platforms/rcorrear ];
    };
  };
}
