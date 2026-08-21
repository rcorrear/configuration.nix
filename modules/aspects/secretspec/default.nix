{ inputs, ... }:
{
  flake-file.inputs.secretspec = {
    url = "github:cachix/secretspec";
    flake = false;
  };

  den.aspects.secretspec = {
    includes = [ ];

    nixos =
      {
        lib,
        pkgs,
        ...
      }:
      {
        imports = [ ../../../packages/secretspec/module.nix ];

        services.secretspec.package = lib.mkDefault (
          pkgs.callPackage ../../../packages/secretspec { inherit (inputs) secretspec; }
        );
      };
  };
}
