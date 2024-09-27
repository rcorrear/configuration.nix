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
      };
    };
  };
}
