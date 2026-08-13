{
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs.opnix = {
    url = "github:brizzbuzz/opnix";
  };

  den.aspects.opnix = {
    includes = [ ];

    nixos =
      { pkgs, ... }:
      {
        imports = [ inputs.opnix.nixosModules.default ];

        environment.systemPackages = [ pkgs.opnix ];

        nixpkgs.overlays = [ inputs.opnix.overlays.default ];

        services.onepassword-secrets.tokenFile = lib.mkDefault "/etc/opnix-token";
      };
  };
}
