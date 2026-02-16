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
          OS,
          ...
        }@ctx:
        # Require OS context so host<->user routes are only expanded once in HM assembly;
        # assert also marks OS as used to pacify deadnix.
        assert builtins.isAttrs OS;
        parametric.fixedTo ctx {
          includes = [
            (mutual user host)
            (mutual host user)
          ];
        };
    in
    routes;
}
