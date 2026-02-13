_: {
  den.aspects.rcorrear-workstation = {
    includes = [ ];

    homeManager = {
      imports = [
        ../../homes/modules/git-signing.nix
        ../../homes/modules/shell-tools.nix
      ];
    };
  };
}
