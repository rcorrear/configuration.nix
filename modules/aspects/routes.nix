{ den, ... }:
{
  den.aspects.routes =
    let
      inherit (den.lib) parametric;
      mutual = from: to: den.aspects.${from.aspect}._.${to.aspect} or { includes = [ ]; };
      routes =
        {
          host,
          user,
          ...
        }@ctx:
        # Keep host<->user routes available in HM internal contexts too.
        # Requiring an `OS` arg here breaks HM propagation because those contexts
        # don't provide it.
        parametric.fixedTo ctx {
          includes = [
            (mutual user host)
            (mutual host user)
          ];
        };
    in
    routes;
}
