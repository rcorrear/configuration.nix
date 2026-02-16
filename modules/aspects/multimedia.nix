_: {
  den.aspects.multimedia = {
    includes = [ ];

    homeManager =
      { lib, pkgs, ... }:
      {
        home.packages = lib.optionals pkgs.stdenv.isLinux [
          pkgs.celluloid
          pkgs.plexamp
          pkgs.vorbis-tools
        ];

        programs.obs-studio = lib.mkIf pkgs.stdenv.isLinux {
          enable = true;
          plugins = with pkgs.obs-studio-plugins; [ obs-pipewire-audio-capture ];
        };

        services.easyeffects.enable = lib.mkIf pkgs.stdenv.isLinux true;
      };
  };
}
