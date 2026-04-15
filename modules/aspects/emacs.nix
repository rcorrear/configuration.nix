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
        baseEmacsPackage = if pkgs.stdenv.isDarwin then pkgs.emacs-macport else pkgs.emacs-pgtk;

        emacsRuntimePath = lib.makeBinPath [
          pkgs.nodejs
          pkgs.uv
        ];

        wrapEmacsRuntime =
          emacsDrv:
          emacsDrv.overrideAttrs (oldAttrs: {
            nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
            postFixup = (oldAttrs.postFixup or "") + ''
              wrapProgram "$out/bin/emacs" --prefix PATH : ${emacsRuntimePath}
            '';
          });

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
          package = wrapEmacsRuntime (
            baseEmacsPackage.overrideAttrs (oldAttrs: {
              propagatedUserEnvPkgs = (oldAttrs.propagatedUserEnvPkgs or [ ]) ++ [
                pkgs.nodejs
                pkgs.uv
              ];
            })
          );
          extraPackages = epkgs: [
            epkgs.emacsql
            epkgs.vterm
          ];
        };
      };
  };
}
