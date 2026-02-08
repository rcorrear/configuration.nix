{ inputs, ... }:
{
  den.aspects.ferrus.darwin = _: {
    imports = [
      ../../../lib/darwin-base.nix
      ../../../lib/darwin-workstation.nix
      ../../../lib/stylix-base.nix
      inputs.home-manager.darwinModules.home-manager
      inputs.stylix.darwinModules.stylix
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
}
