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

      # This value determines the Home Manager release that your
      # configuration is compatible with. This helps avoid breakage
      # when a new Home Manager release introduces backwards
      # incompatible changes.
      #
      # You can update Home Manager without changing this value. See
      # the Home Manager release notes for a list of state version
      # changes in each release.
      stateVersion = "21.05";
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
