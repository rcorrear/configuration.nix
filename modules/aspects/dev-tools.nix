_: {
  den.aspects.dev-tools = {
    includes = [ ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.editorconfig-checker
          pkgs.multimarkdown
          pkgs.nerd-fonts.blex-mono
          pkgs.nerd-fonts.caskaydia-cove
          pkgs.nerd-fonts.iosevka-term-slab
          pkgs.nil
          pkgs.nix-output-monitor
          pkgs.nix-prefetch-git
          pkgs.nixd
          pkgs.nixfmt
          pkgs.nixos-generators
          pkgs.nvd
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
