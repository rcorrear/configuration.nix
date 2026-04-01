_: {
  den.aspects.gaming = {
    includes = [ ];

    homeManager =
      { lib, pkgs, ... }:
      {
        home.packages = lib.optionals pkgs.stdenv.isLinux [
          pkgs.rcorrear.cider-3
          pkgs.rcorrear.exiled-exchange2

          pkgs.atlauncher
          pkgs.lutris
          pkgs.mangohud
          pkgs.moonlight-qt
          pkgs.prismlauncher
          pkgs.sunshine
          pkgs.umu-launcher
          pkgs.wineWowPackages.stagingFull
          pkgs.winetricks
        ];
      };
  };
}
