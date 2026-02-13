_: {
  den.aspects.dev-tools = {
    includes = [ ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.nerd-fonts.blex-mono
          pkgs.nerd-fonts.caskaydia-cove
          pkgs.nerd-fonts.iosevka-term-slab
          pkgs.nixfmt
          pkgs.pijul
          pkgs.pipenv
          pkgs.shellcheck
          pkgs.shfmt
          pkgs.zed
        ];

        programs = {
          git.enable = true;
          jujutsu.enable = true;
        };
      };
  };
}
