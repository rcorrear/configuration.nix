{ lib, ... }:
{
  options.flake.darwinConfigurations = lib.mkOption {
    # Allow multiple modules/hosts to contribute darwin configurations.
    description = "Mergeable Darwin configurations contributed by multiple modules/hosts.";
    type = lib.types.lazyAttrsOf lib.types.unspecified;
    default = { };
  };

  options.flake.homeConfigurations = lib.mkOption {
    # Allow multiple modules/homes to contribute home configurations.
    description = "Mergeable Home Manager configurations contributed by multiple modules/homes.";
    type = lib.types.lazyAttrsOf lib.types.unspecified;
    default = { };
  };
}
