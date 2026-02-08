{ den, ... }:
{
  den.aspects.routes =
    let
      inherit (den.lib) parametric;
      mutual = from: to: den.aspects.${from.aspect}._.${to.aspect} or { includes = [ ]; };
      routes =
        { host, user, ... }@ctx:
        parametric.fixedTo ctx {
          includes = [
            (mutual user host)
            (mutual host user)
          ];
        };
    in
    routes;
}
