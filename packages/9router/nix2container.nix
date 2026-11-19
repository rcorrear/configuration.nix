{ pkgs, source }:
import source {
  pkgs = pkgs // {
    buildGoModule =
      args:
      pkgs.buildGoModule (
        args
        // pkgs.lib.optionalAttrs (args.pname == "nix2container") {
          # Patch src, not postPatch: the exporter vendors this same source
          # through nix2container-bin.src. Both sides must hash identical tars.
          src = pkgs.applyPatches {
            name = "nix2container-relative-layer-paths";
            inherit (args) src;
            patches = [ ./relative-layer-paths.patch ];
          };
        }
      );
  };
}
