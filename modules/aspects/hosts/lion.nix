{ den, inputs, ... }:
# lion runs Determinate Nix, which manages its own Nix daemon and
# `/etc/nix/nix.conf`; see modules/aspects/darwin/determinate.nix. A
# non-Determinate darwin host wouldn't need the `determinateNix` block.
{
  den.aspects.lion = {
    includes = [ den.aspects.darwin-host-common ];

    _.rcorrear.includes = [ den.aspects.rcorrear-darwin ];

    _.rcorrear.homeManager.imports = [ ../../../homes/darwin/lion/rcorrear.nix ];

    darwin = _: {
      imports = [ inputs.determinate.darwinModules.default ];

      # `networking.hostName` comes from `den.batteries.hostname` (see
      # modules/aspects/defaults.nix); the battery doesn't cover the
      # Bonjour/local name, so it is still set manually here.
      networking.localHostName = "lion";

      # Hands `/etc/nix/nix.conf` management over to Determinate Nixd
      # (equivalent to plain `nix.enable = false;`, see
      # https://docs.determinate.systems/guides/nix-darwin/) while
      # declaratively writing custom settings to `/etc/nix/nix.custom.conf`,
      # the only file Determinate Nix allows custom settings in.
      determinateNix = {
        enable = true;
        customSettings.trusted-users = [
          "root"
          "rcorrear"
        ];
      };
    };
  };
}
