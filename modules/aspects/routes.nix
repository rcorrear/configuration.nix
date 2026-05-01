{ den, ... }:
{
  den.aspects.routes =
    let
      inherit (den.lib) parametric;
      aspectRef =
        entity:
        let
          aspect = entity.aspect or null;
        in
        if builtins.isString aspect then den.aspects.${aspect} or null else aspect;
      aspectName =
        entity:
        let
          aspect = entity.aspect or null;
        in
        if builtins.isAttrs aspect && aspect ? name && builtins.isString aspect.name then
          aspect.name
        else if builtins.isString aspect then
          aspect
        else
          entity.name or null;
      mutual =
        from: to:
        let
          toName = aspectName to;
          fromAspect = aspectRef from;
        in
        if fromAspect == null || toName == null then
          { includes = [ ]; }
        else
          fromAspect._.${toName} or { includes = [ ]; };
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
