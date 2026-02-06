{ den, ... }:
{
  den.default.includes = [
    den.aspects.routes
    (den.lib.take.exactly ({ OS, ... }: den.lib.take.unused OS den.aspects.nixos-base))
    den.aspects.nixpkgs-config
  ];
}
