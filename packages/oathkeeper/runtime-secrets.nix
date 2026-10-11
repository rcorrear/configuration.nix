{
  secretDir,
  sessionCheckUrlMarker,
  upstreamUrlMarker,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  oathkeeper = config.services.omni.oathkeeper;
  generatedFiles = config.system.services.oathkeeper.omni.oathkeeper.generatedFiles;
in
{
  systemd.services.oathkeeper = {
    unitConfig.RequiresMountsFor = [ secretDir ];
    preStart = lib.mkBefore ''
      set -euo pipefail

      session_check_host="$(${pkgs.coreutils}/bin/cat "$CREDENTIALS_DIRECTORY/session-check-host")"
      upstream_url="$(${pkgs.coreutils}/bin/cat "$CREDENTIALS_DIRECTORY/upstream-url")"
      runtime_config=/run/oathkeeper/config.yaml
      runtime_rules=/run/oathkeeper/rules.yaml

      rules_uri=${lib.escapeShellArg "file://${generatedFiles.rules}"}
      session_check_url_marker=${lib.escapeShellArg sessionCheckUrlMarker}
      config_content="$(${pkgs.coreutils}/bin/cat ${lib.escapeShellArg generatedFiles.config})"
      config_content="''${config_content//$session_check_url_marker/https://$session_check_host/sessions/whoami}"
      config_content="''${config_content//$rules_uri/file://$runtime_rules}"
      printf '%s\n' "$config_content" > "$runtime_config"

      rules_content="$(${pkgs.coreutils}/bin/cat ${lib.escapeShellArg generatedFiles.rules})"
      rules_content="''${rules_content//${upstreamUrlMarker}/"$upstream_url"}"
      printf '%s\n' "$rules_content" > "$runtime_rules"
    '';
    serviceConfig = {
      ExecStart = lib.mkForce "${lib.getExe oathkeeper.package} serve --disable-telemetry --config /run/oathkeeper/config.yaml";
      LoadCredential = [
        "session-check-host:${secretDir}/session-check-host"
        "upstream-url:${secretDir}/upstream-url"
      ];
      RuntimeDirectory = "oathkeeper";
      RuntimeDirectoryMode = "0700";
      UMask = "0077";
    };
  };
}
