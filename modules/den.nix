{ lib, ... }:
{
  den.schema.user.classes = lib.mkDefault [ "homeManager" ];

  den = {
    hosts = {
      x86_64-linux = {
        hass.users.rcorrear = { };
        OK1EBF.users.rcorrear = { };
        plex.users.rcorrear = { };
        prowlarr.users.rcorrear = { };
        radarr.users.rcorrear = { };
        sonarr.users.rcorrear = { };
        tailscale.users.rcorrear = { };
        files.users.rcorrear = { };
      };
      aarch64-darwin = {
        ferrus.users.rcorrear = { };
        lion.users.rcorrear = { };
      };
    };
    homes.x86_64-linux.rcorrear = { };
    homes.aarch64-darwin.rcorrear = { };
  };
}
