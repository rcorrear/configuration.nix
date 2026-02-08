{
  pkgs,
  ...
}:
let
  jdk25-no-fx = pkgs.jdk25.override { enableJavaFX = false; };
in
{
  imports = [
    ../rcorrear.nix
  ];

  home = {
    packages = [
      (pkgs.clojure.override { jdk = jdk25-no-fx; })
      (pkgs.flix.override { jre = jdk25-no-fx; })
    ];

    stateVersion = "24.11";
  };
}
