{ inputs, lib, ... }:
let
  caches = import ../../../lib/nix-caches.nix;
in
{
  den.aspects.nixos-base.nixos =
    { pkgs, ... }:
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
      ];

      documentation.dev.enable = lib.mkDefault true;

      environment.systemPackages = [ pkgs.cachix ];

      networking = {
        search = [ "home.arpa" ];
        domain = "home.arpa";
      };

      nix.settings = {
        allow-import-from-derivation = lib.mkDefault true;
        auto-optimise-store = lib.mkDefault true;
        substituters = lib.mkDefault caches.substituters;
        trusted-public-keys = lib.mkDefault caches.trusted-public-keys;
      };
    };
}
