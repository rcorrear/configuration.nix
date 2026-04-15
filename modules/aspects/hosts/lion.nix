{ den, ... }:
{
  den.aspects.lion = {
    includes = [ den.aspects.darwin-host-common ];

    _.rcorrear.includes = [ den.aspects.rcorrear-darwin ];

    _.rcorrear.homeManager.imports = [ ../../../homes/darwin/lion/rcorrear.nix ];

    darwin = _: {
      networking = {
        hostName = "lion";
        localHostName = "lion";
      };
    };
  };
}
