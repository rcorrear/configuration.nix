{ den, ... }:
{
  flake-file.inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # Keep an explicit HM aspect and attach it to HM-capable hosts via the new context.
  den.aspects.home-manager = { };
  den.schema.hm-host.includes = [ den.aspects.home-manager ];
}
