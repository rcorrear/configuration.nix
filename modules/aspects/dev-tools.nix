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
          pkgs.multimarkdown
          pkgs.nerd-fonts.blex-mono
          pkgs.nerd-fonts.caskaydia-cove
          pkgs.nerd-fonts.iosevka-term-slab
          pkgs.nil
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
