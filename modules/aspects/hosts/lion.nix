{ den, ... }:
{
  den.aspects.lion = {
    includes = [ den.aspects.darwin-host-common ];

    _.rcorrear.includes = [ den.aspects.rcorrear-darwin ];

    _.rcorrear.homeManager.imports = [ ../../../homes/darwin/lion/rcorrear.nix ];

    darwin = _: {
      # `networking.hostName` comes from `den.batteries.hostname` (see
      # modules/aspects/defaults.nix); the battery doesn't cover the
      # Bonjour/local name, so it is still set manually here.
      networking.localHostName = "lion";
    };
  };
}
