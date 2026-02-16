{ den, ... }:
{
  den.default.includes = [
    den._.home-manager
    den.aspects.nixos-base
    den.aspects.nixpkgs-config
    den.aspects.routes
    den.aspects.timezone
  ];
}
