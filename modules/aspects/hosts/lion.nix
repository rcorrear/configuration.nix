{ den, ... }:
{
  den.aspects.lion = {
    includes = [
      den.aspects.cachix
      den.aspects.darwin-network-services
      den.aspects.darwin-nix-settings
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

    _.rcorrear.homeManager.imports = [ ../../../homes/darwin/lion/rcorrear.nix ];

    darwin = _: {
      networking = {
        hostName = "lion";
        localHostName = "lion";
      };

      nix = {
        settings.trusted-users = [
          "rcorrear"
        ];
      };
    };
  };
}
