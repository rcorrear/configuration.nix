{ config, pkgs, ... }:
let
  base = import ../../all-platforms/base;
in
{
  imports = [
    base
  ];

  config = {
    home = {
      keyboard = {
        options = [ "caps:escape" ];
      };

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
    };

    programs = {
      git = {
        enable = true;
        userEmail = "r.correa.r@gmail.com";
        userName = "Ricardo Correa";
        extraConfig = {
          "gpg \"ssh\"".program = "${pkgs._1password-gui}/bin/op-ssh-sign";
          commit.gpgsign = true;
          github.user = "rcorrear";
          gpg.format = "ssh";
          pull.ff = "only";
        };
      };

      jujutsu = {
        ediff = true;
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
