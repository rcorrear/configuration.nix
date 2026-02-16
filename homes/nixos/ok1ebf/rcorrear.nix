{ pkgs, ... }:
{
  imports = [
    ../../all/rcorrear.nix
  ];

  home = {
    keyboard = {
      options = [ "caps:escape" ];
    };

    packages = [
      pkgs.arcan
      pkgs.cat9
      pkgs.durden
      pkgs.pipeworld
      pkgs.prio
      pkgs.xarcan

      pkgs.font-awesome
      pkgs.gwe
      pkgs.nvtopPackages.nvidia
      pkgs.piper
    ];

    stateVersion = "21.05";
  };
}
