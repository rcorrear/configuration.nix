{ den, ... }:
{
  den.aspects.editors = {
    includes = [ den.aspects.emacs ];

    darwin = _: {
      homebrew = {
        casks = [
          "zed"
        ];
      };
    };

    homeManager =
      { lib, pkgs, ... }:
      {
        home.packages = lib.optionals pkgs.stdenv.isLinux [
          pkgs.jetbrains.idea-oss
          pkgs.jetbrains.rider
        ];
      };
  };
}
