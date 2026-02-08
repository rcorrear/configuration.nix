{ inputs, den, ... }:
{
  den.aspects.ferrus = {
    includes = [
      den.aspects.cachix
      den.aspects.darwin-workstation
      den.aspects.nix-caches
      den.aspects.stylix-base
    ];

    darwin = _: {
      imports = [
        inputs.home-manager.darwinModules.home-manager
      ];

      home-manager = {
        users.rcorrear = {
          imports = [
            ../../../homes/all/rcorrear.nix
            ../../../homes/darwin/ferrus/rcorrear.nix
          ];
        };
      };

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
