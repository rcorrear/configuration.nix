{ den, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      # Exposes `nix run .#<host>` / `nix run .#<host> -- switch` and
      # `nix run .#<user>@<host>` apps for every host/home declared in
      # modules/den.nix, via den's own nh integration.
      packages = den.lib.nh.denPackages { fromFlake = true; } pkgs;
    };
}
