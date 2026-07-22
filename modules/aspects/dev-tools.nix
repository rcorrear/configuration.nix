_: {
  den.aspects.dev-tools = {
    includes = [ ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
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
          pkgs.pijul
          pkgs.pipenv
          pkgs.pre-commit
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
          fish.shellAbbrs = {
            jjd = "jj diff";
            jjgf = "jj git fetch";
            jjgp = "jj git push";
            jjl = "jj log";
            jjrb = "jj rebase";
            jjsq = "jj squash";
            jjt = "jj tug";
            "jjt-" = "jj tug-";
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
              fix.tools.nixfmt = {
                command = [ "${pkgs.nixfmt}/bin/nixfmt" ];
                patterns = [ "glob:'**/*.nix'" ];
              };
              fsmonitor = {
                backend = "watchman";
                watchman.register-snapshot-trigger = true;
              };
              ui = {
                default-command = "status";
                diff-formatter = [
                  "${pkgs.difftastic}/bin/difft"
                  "--color=always"
                  "$left"
                  "$right"
                ];
              };
            };
          };
        };
      };
  };
}
