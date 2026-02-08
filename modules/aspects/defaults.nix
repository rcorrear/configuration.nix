{ den, ... }:
{
  den.default.includes = [
    den.aspects.nixos-base
    den.aspects.nixpkgs-config
    den.aspects.timezone
  ];
}
