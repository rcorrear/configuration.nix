{
  den,
  inputs,
  lib,
  ...
}:
{
  den.aspects.nixos-base = {
    includes = [ den.aspects.zmx ];

    nixos =
      { ... }:
      {
        imports =
          let
            ciModulePath = ../../ci-runtime.nix;
          in
          lib.optionals (builtins.pathExists ciModulePath) [ ciModulePath ]
          ++ [
            ../../nixos/user-ids.nix
            inputs.home-manager.nixosModules.home-manager
          ];

        home-manager.useGlobalPkgs = lib.mkDefault false;

        documentation = {
          dev.enable = lib.mkDefault true;
          man.cache.enable = lib.mkDefault true;
        };

        programs.fish.enable = lib.mkDefault true;

        networking = {
          search = lib.mkDefault [ "home.arpa" ];
          domain = lib.mkDefault "home.arpa";
          nftables.enable = lib.mkDefault true;
        };

        nix.settings = {
          allow-import-from-derivation = lib.mkDefault true;
          auto-optimise-store = lib.mkDefault true;
          experimental-features = lib.mkDefault [
            "nix-command"
            "flakes"
          ];
        };
      };
  };
}
