{ den, ... }:
{
  den.aspects.darwin-host-common = {
    includes = [
      den.aspects.cachix
      den.aspects.darwin-network-services
      den.aspects.darwin-nix-settings
      den.aspects.darwin-workstation
      den.aspects.nix-caches
      den.aspects.stylix
    ];
  };
}
