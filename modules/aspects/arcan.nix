_: {
  den.aspects.arcan = {
    includes = [ ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.arcan
          pkgs.cat9
          pkgs.durden
          pkgs.pipeworld
          pkgs.prio
          pkgs.xarcan
        ];
      };
  };
}
