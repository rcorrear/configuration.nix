_: {
  den.aspects.timezone = {
    includes = [ ];
    # Defaults to the flake author's timezone; override per-host, e.g. in
    # your host's aspect file: `darwin.time.timeZone = lib.mkForce "...";`.
    darwin =
      { lib, ... }:
      {
        time.timeZone = lib.mkDefault "America/New_York";
      };
    nixos =
      { lib, ... }:
      {
        time.timeZone = lib.mkDefault "America/New_York";
      };
  };
}
