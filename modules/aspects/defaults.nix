{ den, ... }:
{
  den.default.includes = [
    # Cross-entity routing (host<->user `provides`, to-users/to-hosts) is
    # built into den itself now, so no explicit routing aspect is needed.
    den.aspects.nixos-base
    den.aspects.nixpkgs-config
    den.aspects.timezone
  ];
}
