{ lib, ... }:
{
  # home-manager module must be imported by host (they have access to inputs)
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = false; # Packages are still installed into the home user profile dir via home-manager.
  };

  programs.fish.enable = lib.mkDefault true;
}
