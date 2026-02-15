_: {
  den.aspects.dev-lang = {
    includes = [ ];

    homeManager =
      { pkgs, ... }:
      let
        local = rec {
          jdk25 = pkgs.jdk25.override { enableJavaFX = false; };
          clojure = pkgs.clojure.override { jdk = jdk25; };
        };
      in
      {
        home = {
          packages = [
            local.clojure

            (pkgs.flix.override { jre = local.jdk25; })

            pkgs.clang
            pkgs.cmake
            pkgs.exercism
            pkgs.jdk25
            pkgs.metals
            pkgs.nodePackages.bash-language-server
            pkgs.nodejs
            pkgs.python3
            pkgs.sqlite
            pkgs.unison-ucm
          ];
        };
      };
  };
}
