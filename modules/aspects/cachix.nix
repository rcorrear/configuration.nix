{
  den.aspects.cachix = {
    includes = [ ];

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.cachix ];
      };

    darwin =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.cachix ];
      };
  };
}
