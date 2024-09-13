{ config, pkgs, ... }:
{
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
    };

    programs = {
      git = {
        enable = true;
        userName = "Ricardo Correa";
        userEmail = "r.correa.r@gmail.com";
        extraConfig = {
          "gpg \"ssh\"".program = "${pkgs._1password-gui}/bin/op-ssh-sign";
          commit.gpgsign = true;
          github.user = "rcorrear";
          gpg.format = "ssh";
          pull.ff = "only";
          safe.directory = "${config.home.homeDirectory}/Projects/nix/flake";
          user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKa59A0LGSduyaIk+rKKImRNoeJBTQV9pvvUNJJqg6cC";
        };
      };
    };
  };
}
