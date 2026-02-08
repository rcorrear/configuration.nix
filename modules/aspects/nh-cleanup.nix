{
  den.aspects.nh-cleanup = {
    includes = [ ];

    nixos = {
      programs.nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 14d --keep 5";
      };
    };
  };
}
