{
  pkgs,
  ...
}:
{
  imports = [
    ../rcorrear.nix
  ];

  home = {
    packages = [
      (pkgs.flix.override { jre = pkgs.jdk25; })
    ];

    stateVersion = "24.11";
  };
}
