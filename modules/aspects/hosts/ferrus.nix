{ den, ... }:
{
  den.aspects.ferrus = {
    includes = [ den.aspects.darwin-host-common ];

    _.rcorrear.includes = [ den.aspects.rcorrear-darwin ];

    _.rcorrear.homeManager.imports = [ ../../../homes/darwin/ferrus/rcorrear.nix ];

    darwin = _: {
      networking = {
        hostName = "ferrus";
        localHostName = "ferrus";
      };
    };
  };
}
