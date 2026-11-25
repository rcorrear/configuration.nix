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
          "karere"
          "keybase-gui"
          "slack"
        ];
      in
      {
        nixpkgs.config.permittedInsecurePackages = [
          "keybase-gui-6.6.3"
        ];

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
