{
  inputs,
  lib,
  self,
  ...
}:
{
  flake-file.inputs.treefmt-nix = {
    url = "github:numtide/treefmt-nix";
  };

  imports = lib.optionals (inputs ? treefmt-nix) [ inputs.treefmt-nix.flakeModule ];
}
// lib.optionalAttrs (inputs ? treefmt-nix) {
  perSystem =
    { config, ... }:
    {
      treefmt = {
        projectRootFile = "flake.nix";
        programs = {
          deadnix.enable = true;
          nixfmt.enable = true;
          shfmt.enable = true;
          yamllint.enable = true;
          yamlfmt.enable = true;
        };
      };

      checks.formatting = config.treefmt.build.check self;
      formatter = config.treefmt.build.wrapper;
    };
}
