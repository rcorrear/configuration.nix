{
  den,
  inputs,
  self,
  ...
}:
{
  flake-file.inputs.secretspec = {
    url = "github:cachix/secretspec";
    flake = false;
  };

  perSystem =
    { pkgs, ... }:
    {
      packages.secretspec = pkgs.callPackage ../../../packages/secretspec {
        inherit (inputs) secretspec;
      };
    };

  den.aspects.secretspec = {
    includes = [ den.aspects.opnix ];

    nixos =
      {
        lib,
        pkgs,
        ...
      }:
      {
        imports = [ ../../../packages/secretspec/module.nix ];

        services.secretspec.package = lib.mkDefault self.packages.${pkgs.system}.secretspec;
      };
  };
}
