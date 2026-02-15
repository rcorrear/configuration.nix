_: {
  den.aspects.emacs = {
    includes = [ ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        emacsDaemonDarwinModule =
          {
            config,
            pkgs,
            ...
          }:
          lib.mkIf pkgs.stdenv.isDarwin {
            launchd.agents.emacs-daemon = {
              enable = true;
              config = {
                Label = "emacs-daemon";
                ProgramArguments = [
                  "${config.programs.emacs.finalPackage}/bin/emacs"
                  "--fg-daemon"
                ];
                RunAtLoad = true;
                KeepAlive = true;
              };
            };
          };

        emacsDaemonNixosModule =
          { lib, pkgs, ... }:
          lib.mkIf pkgs.stdenv.isLinux {
            services.emacs = {
              enable = true;
              client.enable = true;
              defaultEditor = true;
              startWithUserSession = true;
            };
          };
      in
      {
        imports = [
          emacsDaemonDarwinModule
          emacsDaemonNixosModule
        ];

        home = {
          packages = [
            pkgs.emacs-all-the-icons-fonts
          ];
          sessionPath = [
            "${config.xdg.configHome}/emacs/bin"
          ];
        };

        programs.emacs = {
          enable = true;
          extraPackages = epkgs: [
            epkgs.emacsql
            epkgs.vterm
          ];
          package = pkgs.emacs30.overrideAttrs (oldAttrs: {
            propagatedUserEnvPkgs = (oldAttrs.propagatedUserEnvPkgs or [ ]) ++ [
              (pkgs.aspellWithDicts (dicts: [ dicts.en ]))
              pkgs.enchant
              pkgs.nodejs
              pkgs.uv
            ];
          });
        };
      };
  };
}
