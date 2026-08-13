_: {
  den.aspects.dev-tools = {
    includes = [ ];

    darwin.homebrew.casks = [ "stablyai/orca/orca" ];

    homeManager =
      { lib, pkgs, ... }:
      {
        home.packages = [
          pkgs.devcontainer
          pkgs.devenv
          pkgs.editorconfig-checker
          pkgs.gg-jj
          pkgs.gh
          pkgs.rcorrear.jj-waltz
          pkgs.multimarkdown
          pkgs.nerd-fonts.blex-mono
          pkgs.nerd-fonts.caskaydia-cove
          pkgs.nerd-fonts.iosevka-term-slab
          pkgs.nixd
          pkgs.nixfmt
          pkgs.pipenv
          pkgs.pre-commit
          pkgs.shellcheck
          pkgs.shfmt
          pkgs.watchman
          pkgs.zed
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.rcorrear.orca ];

        programs = {
          difftastic = {
            enable = true;
            git.enable = true;
          };
          fish = {
            shellAbbrs = {
              jjd = "jj diff";
              jjdd = "jj edit";
              jjgf = "jj git fetch";
              jjgp = "jj git push";
              jjl = "jj log";
              jjn = "jj new";
              jjrb = "jj rebase";
              jjsq = "jj squash";
              jjt = "jj tug";
              "jjt-" = "jj tug-";
            };
          };
          git.enable = true;
          jujutsu = {
            enable = true;
            settings = {
              fsmonitor = {
                backend = "watchman";
                watchman.register-snapshot-trigger = true;
              };
            };
          };
        };
      };
  };
}
