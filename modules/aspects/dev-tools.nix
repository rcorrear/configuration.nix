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
          pkgs.zed
        ];

        programs = {
          difftastic = {
            enable = true;
            git.enable = true;
          };
          git.enable = true;
          jujutsu.enable = true;
        };
      };
  };
}
