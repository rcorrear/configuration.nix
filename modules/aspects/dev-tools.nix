_: {
  den.aspects.dev-tools = {
    includes = [ ];

    homeManager =
      { pkgs, ... }:
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
          pkgs.secretspec
          pkgs.shellcheck
          pkgs.shfmt
          pkgs.watchman
          pkgs.zed
        ];

        programs = {
          difftastic = {
            enable = true;
            git.enable = true;
          };
          fish = {
            interactiveShellInit = ''
              ${pkgs.devenv}/bin/devenv hook fish | source
            '';
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
              aliases = {
                rebase-onto = [
                  "util"
                  "exec"
                  "--"
                  "${pkgs.coreutils}/bin/env"
                  "sh"
                  "-c"
                  "jj rebase -s \"roots(mutable() ~ ::$0)\" -o \"$0\""
                ];
                rebase-trunk = [
                  "rebase"
                  "-s"
                  "roots(mutable() ~ ::trunk())"
                  "-o"
                  "trunk()"
                ];
                tug = [
                  "bookmark"
                  "move"
                  "--from"
                  "heads(::@- & bookmarks())"
                  "--to"
                  "@"
                ];
                "tug-" = [
                  "bookmark"
                  "move"
                  "--from"
                  "heads(::@- & bookmarks())"
                  "--to"
                  "@-"
                ];
              };
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
