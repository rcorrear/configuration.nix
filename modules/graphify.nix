_: {
  perSystem =
    { pkgs, ... }:
    let
      graphify = pkgs.callPackage ../packages/graphify { };
      lifecycle = pkgs.callPackage ../packages/graphify/lifecycle.nix { inherit graphify; };
    in
    {
      packages = {
        inherit graphify;
        graphify-build = lifecycle.build;
        graphify-sync = lifecycle.sync;
      };

      apps = {
        graphify-build = {
          type = "app";
          program = "${lifecycle.build}/bin/graphify-build";
          meta.description = "Build and validate a deterministic Graphify baseline";
        };
        graphify-sync = {
          type = "app";
          program = "${lifecycle.sync}/bin/graphify-sync";
          meta.description = "Restore an exact-SHA Graphify artifact or rebuild locally";
        };
      };

      checks = {
        inherit graphify;
        graphify-lifecycle-tests = lifecycle.tests;
        graphify-command-help = lifecycle.commandHelp;
      };
    };
}
