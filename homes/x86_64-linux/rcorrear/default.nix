{
  config,
  lib,
  pkgs,
  ...
}:
let
  base = import ../../all-platforms/base;
in
{
  imports = [
    base
  ];

  config = {
    home = {
      packages = with pkgs; [
        any-nix-shell
        coreutils
        fd
        file
        htop
        jq
        ripgrep
        tree
      ];

      sessionVariables = {
        PAGER = "${pkgs.less}/bin/less -FRSX";
      };

      stateVersion = lib.mkDefault "24.05";
    };

    programs = {
      git = {
        enable = true;
        userEmail = "r.correa.r@gmail.com";
        userName = "Ricardo Correa";
        extraConfig = {
          github.user = "rcorrear";
          pull.ff = "only";
        };
      };

      jujutsu = {
        enable = true;
        settings = {
          user = {
            email = "r.correa.r@gmail.com";
            name = "Ricardo Correa";
          };
        };
      };
    };
  };
}
