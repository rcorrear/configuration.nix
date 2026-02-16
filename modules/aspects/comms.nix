_: {
  den.aspects.comms = {
    includes = [ ];

    homeManager =
      { lib, pkgs, ... }:
      let
        pkgOrNull = name: lib.attrByPath [ name ] null pkgs;
        commsPkgNames = [
          "discord"
          "element-call"
          "element-desktop"
          "fractal"
          "keybase-gui"
          "slack"
          "stoat-desktop"
          "wasistlos"
        ];
      in
      {
        home.packages = builtins.filter (p: p != null) (builtins.map pkgOrNull commsPkgNames);

        services = {
          kbfs = {
            enable = true;
            mountPoint = "Keybase";
          };
        };
      };
  };
}
