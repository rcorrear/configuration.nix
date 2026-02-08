{ config, lib, ... }:
{
  options.den.userIds = lib.mkOption {
    type = lib.types.attrsOf lib.types.int;
    default = {
      rcorrear = 5000;
      elizabethfeitof = 5001;
    };
    description = "Canonical UID map for local users.";
  };

  config._module.args.userIds = config.den.userIds;
}
