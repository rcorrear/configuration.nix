{ den, ... }:
{
  den.default.includes =
    let
      hm = ctx: (den._.home-manager ctx) // { includes = [ ]; }; # Clear HM includes to avoid default include chains conflicting with den.aspects routing.
    in
    [
      hm
      den.aspects.nixos-base
      den.aspects.nixpkgs-config
      den.aspects.routes
      den.aspects.timezone
    ];
}
