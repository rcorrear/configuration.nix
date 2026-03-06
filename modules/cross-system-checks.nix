{ lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    lib.mkIf pkgs.stdenv.isDarwin {
      # Avoid running build-time checks for Darwin systems in flake check.
      checks = lib.mkForce { };
    };
}
