{
  graphify,
  pkgs,
}:
let
  project = ../../tools/graphify;
  mkBabashkaCommand =
    {
      name,
      mainNamespace,
      runtimeInputs ? [ ],
    }:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [ pkgs.babashka ] ++ runtimeInputs;
      text = ''
        exec ${pkgs.babashka}/bin/bb --classpath ${project}/src --main ${mainNamespace} "$@"
      '';
    };
  graphifyBuild = mkBabashkaCommand {
    name = "graphify-build";
    mainNamespace = "configuration-nix.graphify.build";
    runtimeInputs = [
      graphify
      pkgs.git
      pkgs.gnutar
      pkgs.zstd
    ];
  };
  graphifySync = mkBabashkaCommand {
    name = "graphify-sync";
    mainNamespace = "configuration-nix.graphify.sync";
    runtimeInputs = [
      graphify
      graphifyBuild
      pkgs.gh
      pkgs.git
      pkgs.gnutar
      pkgs.unzip
      pkgs.zstd
    ];
  };
in
{
  build = graphifyBuild;
  sync = graphifySync;
  tests = pkgs.runCommand "graphify-lifecycle-tests" { nativeBuildInputs = [ pkgs.babashka ]; } ''
    cd ${project}
    bb test
    touch "$out"
  '';
  commandHelp =
    pkgs.runCommand "graphify-command-help"
      {
        nativeBuildInputs = [
          graphifyBuild
          graphifySync
        ];
      }
      ''
        graphify-build --help >/dev/null
        graphify-sync --help >/dev/null
        touch "$out"
      '';
}
