{
  pkgs,
  secretspec,
  onepasswordCli,
  vault ? "9Router Production",
  item ? "9router",
  secretsDir ? "/run/secrets",
}:
let
  inherit (pkgs) lib;
  fields = {
    INITIAL_PASSWORD = "initial-password";
    JWT_SECRET = "jwt-secret";
    API_KEY_SECRET = "api-key-secret";
    MACHINE_ID_SALT = "machine-id-salt";
  };
  manifest = (pkgs.formats.toml { }).generate "9router-secretspec.toml" {
    project = {
      name = "9router";
      revision = "1.0";
    };
    providers.op = {
      uri = "onepassword+token://";
      credentials.service_account_token = {
        provider = "file://${secretsDir}";
        ref.item = "onepassword-token";
      };
    };
    profiles.default = lib.mapAttrs (_: field: {
      description = "Existing 9Router deployment secret";
      required = true;
      providers = [ "op" ];
      ref = { inherit vault item field; };
    }) fields;
    scopes."9router".secrets = builtins.attrNames fields;
  };
  dropPrivileges = pkgs.writeShellScript "9router-drop-privileges" ''
    # Do not expose resolver configuration/cache locations to the application.
    unset OP_CONFIG_DIR OP_SERVICE_ACCOUNT_TOKEN SECRETSPEC_OPCLI_PATH
    unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_CACHE_HOME XDG_STATE_HOME
    exec ${pkgs.util-linux}/bin/setpriv \
      --reuid=1000 --regid=1000 --clear-groups \
      --bounding-set=-all --inh-caps=-all --ambient-caps=-all \
      --no-new-privs -- "$@"
  '';
  launcher = pkgs.writeShellApplication {
    name = "9router-secretspec";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      if [ "$(id -u)" != 0 ]; then
        echo "9Router: the secret resolver must start as container root" >&2
        exit 1
      fi
      if [ ! -s ${lib.escapeShellArg "${secretsDir}/onepassword-token"} ] ||
         [ ! -r ${lib.escapeShellArg "${secretsDir}/onepassword-token"} ]; then
        echo "9Router: 1Password bootstrap token is missing or unreadable" >&2
        exit 1
      fi
      # Fail closed if provisioning accidentally exposes the token to the app.
      case "$(stat -c '%u:%a' ${lib.escapeShellArg secretsDir})" in
        0:500|0:700) ;;
        *) echo "9Router: bootstrap directory must be root-owned and root-only" >&2; exit 1 ;;
      esac
      case "$(stat -c '%u:%a' ${lib.escapeShellArg "${secretsDir}/onepassword-token"})" in
        0:400|0:600) ;;
        *) echo "9Router: bootstrap token must be root-owned and root-only" >&2; exit 1 ;;
      esac
      # Credentials resolved by SecretSpec stay internal, not in the app environment.
      unset OP_SERVICE_ACCOUNT_TOKEN
      export SECRETSPEC_OPCLI_PATH=${lib.getExe onepasswordCli}
      umask 077
      runtime="$(mktemp -d /tmp/9router-secretspec.XXXXXXXX)"
      trap 'rm -rf "$runtime"' EXIT
      export XDG_CONFIG_HOME="$runtime/config"
      export XDG_DATA_HOME="$runtime/data"
      export XDG_CACHE_HOME="$runtime/cache"
      export XDG_STATE_HOME="$runtime/state"
      export OP_CONFIG_DIR="$runtime/op"
      export HOME="$runtime"
      mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME" "$OP_CONFIG_DIR"
      # Root never loads configuration from the application-writable data volume.
      cd "$runtime"
      ${lib.getExe secretspec} run --file ${manifest} \
        --profile default --provider op --scope 9router -- ${dropPrivileges} "$@" &
      child=$!
      trap 'kill -TERM "$child" 2>/dev/null || true' TERM INT
      status=0
      wait "$child" || status=$?
      if kill -0 "$child" 2>/dev/null; then
        wait "$child" || status=$?
      fi
      exit "$status"
    '';
  };
in
{
  inherit manifest launcher;
}
