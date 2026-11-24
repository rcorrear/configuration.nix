{
  package,
  pkgs,
  secretRuntime,
}:
{
  config,
  lib,
  ...
}:
let
  cfg = config."9router";
  application = pkgs.writeShellApplication {
    name = "9router-application";
    text = ''
      : "''${INITIAL_PASSWORD:?INITIAL_PASSWORD must be provisioned}"
      : "''${JWT_SECRET:?JWT_SECRET must be provisioned}"
      : "''${API_KEY_SECRET:?API_KEY_SECRET must be provisioned}"
      : "''${MACHINE_ID_SALT:?MACHINE_ID_SALT must be provisioned}"

      export DATA_DIR=${lib.escapeShellArg cfg.dataDir}
      export HOME="$DATA_DIR"
      export HOSTNAME=${lib.escapeShellArg cfg.address}
      export PORT=${toString cfg.port}
      export REQUIRE_API_KEY=true
      export MITM_SERVER_PATH=${package}/lib/9router/app/src/mitm/server.js
      if [ ! -d "$DATA_DIR" ] || [ ! -w "$DATA_DIR" ]; then
        echo "9Router: the persistent data directory must exist and be writable" >&2
        exit 1
      fi
      cd "$DATA_DIR"
      exec ${lib.getExe package}
    '';
  };
  runner = pkgs.writeShellApplication {
    name = "9router-service";
    text = ''
      exec ${lib.getExe secretRuntime.launcher} ${lib.getExe application}
    '';
  };
in
{
  _class = "service";
  options."9router" = {
    address = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Private backend listener; restrict access with the deployment firewall.";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 20128;
      description = "Private backend HTTP port.";
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/9router";
      description = "Persistent volume mounted by the container host.";
    };
  };
  config.process.argv = [ (lib.getExe runner) ];
}
