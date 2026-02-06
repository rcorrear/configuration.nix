{ lib, ... }:
let
  caches = import ./nix-caches.nix;
  ciModulePath = ./ci-runtime.nix;
in
{
  # Conditionally import CI module if it exists (created during CI)
  imports = lib.optionals (builtins.pathExists ciModulePath) [ ciModulePath ];

  # home-manager module must be imported by host (they have access to inputs)
  home-manager.useGlobalPkgs = true;

  documentation.man.generateCaches = lib.mkDefault true;

  nix.settings = {
    substituters = lib.mkDefault caches.substituters;
    trusted-public-keys = lib.mkDefault caches.trusted-public-keys;
  };

  programs.fish.enable = lib.mkDefault true;
}
