{ den, ... }:
{
  den.aspects.editors = {
    includes = [ den.aspects.emacs ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.jetbrains.idea-oss
          pkgs.jetbrains.rider
          pkgs.zed-editor
        ];
      };
  };
}
