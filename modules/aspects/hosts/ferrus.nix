{ den, ... }:
{
  den.aspects.ferrus = {
    includes = [
      den.aspects.cachix
      den.aspects.darwin-workstation
      den.aspects.nix-caches
      den.aspects.stylix
    ];

    _.rcorrear.includes = [
      den.aspects.dev-lang
      den.aspects.dev-tools
      den.aspects.editors
      den.aspects.llm-tools
      den.aspects.rcorrear-workstation
    ];

    _.rcorrear.homeManager.imports = [ ../../../homes/darwin/ferrus/rcorrear.nix ];

    darwin = _: {
      networking = {
        hostName = "ferrus";
        localHostName = "ferrus";
        knownNetworkServices = [
          "Thunderbolt Bridge"
          "USB 10/100/1000 LAN"
          "Wi-Fi"
          "iPhone USB"
        ];
      };

      nix = {
        enable = false;
        channel.enable = false;
        settings.trusted-users = [
          "rcorrear"
        ];
      };

      system = {
        primaryUser = "rcorrear";
        stateVersion = 4;
      };
    };
  };
}
