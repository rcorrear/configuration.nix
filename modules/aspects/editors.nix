{ den, ... }:
{
  den.aspects.editors = {
    includes = [ den.aspects.emacs ];

    homeManager =
      { lib, pkgs, ... }:
      {
        home.packages = [
          pkgs.zed-editor
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [
          pkgs.jetbrains.idea-oss
          pkgs.jetbrains.rider
        ];
      };
  };
}
