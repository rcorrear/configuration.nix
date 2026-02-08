{ lib, ... }:
{
  den.aspects.darwin-base = {
    includes = [ ];

    darwin = {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = false; # Packages are still installed into the home user profile dir via home-manager.
      };

      programs.fish.enable = lib.mkDefault true;
    };
  };
}
