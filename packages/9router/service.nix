{
  package,
  pkgs,
  secretRuntime ? null,
}:
{
  config,
  lib,
  ...
}:
let
  cfg = config.nineRouter;
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
    text =
      if secretRuntime != null then
        ''
          exec ${lib.getExe secretRuntime.launcher} ${lib.getExe application}
        ''
      else
        ''
          # This is an operator-provided shell environment file, never a store path.
          if [ ! -r ${lib.escapeShellArg cfg.environmentFile} ]; then
            echo "9Router: runtime secret file is missing or unreadable" >&2
            exit 1
          fi
          set -a
          # shellcheck disable=SC1091
          . ${lib.escapeShellArg cfg.environmentFile}
          set +a
          exec ${lib.getExe application}
        '';
  };
in
{
  _class = "service";
  options.nineRouter = {
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
    environmentFile = lib.mkOption {
      type = lib.types.str;
      default = "/run/secrets/9router.env";
      description = "Trusted runtime shell environment file, provisioned outside the image.";
    };
  };
  config.process.argv = [ (lib.getExe runner) ];
}
