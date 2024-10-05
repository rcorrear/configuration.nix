{
  config,
  lib,
  pkgs,
  ...
}:
let
  rcorrear-all = import ../../all-platforms/rcorrear;
in
{
  imports = [
    rcorrear-all
  ];

  config = {
    home = {
      # This value determines the Home Manager release that your
      # configuration is compatible with. This helps avoid breakage
      # when a new Home Manager release introduces backwards
      # incompatible changes.
      #
      # You can update Home Manager without changing this value. See
      # the Home Manager release notes for a list of state version
      # changes in each release.
      stateVersion = "24.05";
    };
  };
}
