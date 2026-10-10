{
  pkgs,
}:
{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.omni.oathkeeper;
  runtimeRulesFile = "/run/oathkeeper/rules.yaml";
  sessionCheckUrlEnv = "AUTHENTICATORS_COOKIE_SESSION_CONFIG_CHECK_SESSION_URL";
  sessionCheckUrlPattern = import ./session-check-url.nix;
  upstreamUrlEnv = "OMNI_OATHKEEPER_UPSTREAM_URL";
  yaml = pkgs.formats.yaml { };
  rulesFile = yaml.generate "oathkeeper-rules.yaml" [
    {
      authenticators = [ { handler = "cookie_session"; } ];
      authorizer.handler = "allow";
      id = "omni-user-api";
      match = {
        methods = [
          "DELETE"
          "GET"
          "HEAD"
          "OPTIONS"
          "PATCH"
          "POST"
          "PUT"
        ];
        url = "<http|https>://<.*>/api/<.*>";
      };
      mutators = [
        {
          config.headers = {
            Authorization = "";
            Cookie = "";
            X-Omni-Auth-Email-Verified = ''{{- $verified := false -}} {{- range .Extra.identity.verifiable_addresses -}} {{- if and .verified (eq .via "email") (eq .value $.Extra.identity.traits.email) -}} {{- $verified = true -}} {{- end -}} {{- end -}} {{- $verified }}'';
            X-Omni-Auth-Identity-Active = ''{{ eq .Extra.identity.state "active" }}'';
            X-Omni-Auth-Ory-Identity-Id = "{{ print .Subject }}";
            X-Omni-Auth-Session-Active = "{{ print .Extra.active }}";
            X-Omni-Auth-Session-Expires-At = "{{ print .Extra.expires_at }}";
          };
          handler = "header";
        }
      ];
      upstream = {
        preserve_host = false;
        preserve_path = true;
        url = if cfg.upstreamUrl == null then "\${${upstreamUrlEnv}}" else cfg.upstreamUrl;
      };
    }
  ];
  configFile = yaml.generate "oathkeeper-config.yaml" {
    access_rules.repositories = [
      "file://${if cfg.upstreamUrl == null then runtimeRulesFile else rulesFile}"
    ];
    authenticators.cookie_session = {
      config = {
        extra_from = "@this";
        force_method = "GET";
        forward_http_headers = [ "Cookie" ];
        preserve_path = true;
        preserve_query = true;
        subject_from = "identity.id";
      }
      // lib.optionalAttrs (cfg.sessionCheckUrl != null) {
        check_session_url = cfg.sessionCheckUrl;
      };
      enabled = true;
    };
    authorizers.allow.enabled = true;
    errors = {
      fallback = [ "json" ];
      handlers.json = {
        config.verbose = false;
        enabled = true;
      };
    };
    log.level = "error";
    mutators.header = {
      config.headers = { };
      enabled = true;
    };
    serve = {
      api = {
        inherit (cfg.api) host port;
      };
      prometheus = {
        inherit (cfg.metrics) host port;
      };
      proxy = {
        inherit (cfg.proxy) host port;
        trust_forwarded_headers = false;
      };
    };
  };
in
{
  _class = "service";

  options.omni.oathkeeper = {
    generatedFiles = lib.mkOption {
      internal = true;
      readOnly = true;
      description = "Exact generated Oathkeeper configuration and access-rule paths.";
      type = lib.types.attrsOf lib.types.path;
    };
    environmentFile = lib.mkOption {
      default = null;
      description = "Runtime environment file read by the Oathkeeper service.";
      type = lib.types.nullOr lib.types.str;
    };
    package = lib.mkOption {
      default = pkgs.oathkeeper;
      description = "Oathkeeper package to run.";
      type = lib.types.package;
    };
    sessionCheckUrl = lib.mkOption {
      description = "Exact Ory /sessions/whoami URL over HTTPS or loopback HTTP, or null to read ${sessionCheckUrlEnv} at runtime.";
      type = lib.types.nullOr (lib.types.strMatching sessionCheckUrlPattern);
    };
    upstreamUrl = lib.mkOption {
      description = "Internal user API URL, or null to read ${upstreamUrlEnv} at runtime.";
      type = lib.types.nullOr (lib.types.strMatching ".+");
    };
    proxy = {
      host = lib.mkOption {
        default = "0.0.0.0";
        description = "Address for Oathkeeper proxy listener.";
        type = lib.types.str;
      };
      port = lib.mkOption {
        default = 4455;
        description = "Port for Oathkeeper proxy listener.";
        type = lib.types.port;
      };
    };
    api = {
      host = lib.mkOption {
        default = "127.0.0.1";
        description = "Address for Oathkeeper decision API listener.";
        type = lib.types.str;
      };
      port = lib.mkOption {
        default = 4456;
        description = "Port for Oathkeeper decision API listener.";
        type = lib.types.port;
      };
    };
    metrics = {
      host = lib.mkOption {
        default = "127.0.0.1";
        description = "Address for Oathkeeper Prometheus listener.";
        type = lib.types.str;
      };
      port = lib.mkOption {
        default = 9000;
        description = "Port for Oathkeeper Prometheus listener.";
        type = lib.types.port;
      };
    };
  };

  config = {
    omni.oathkeeper.generatedFiles = {
      config = configFile;
      rules = rulesFile;
    };

    assertions = [
      {
        assertion = lib.getVersion cfg.package == "26.2.0";
        message = "Oathkeeper package must remain at reviewed version 26.2.0";
      }
    ];

    process.argv = [
      "${pkgs.coreutils}/bin/env"
    ]
    ++ lib.optionals (cfg.sessionCheckUrl != null) [ "--unset=${sessionCheckUrlEnv}" ]
    ++ lib.optionals (cfg.upstreamUrl != null) [ "--unset=${upstreamUrlEnv}" ]
    ++ [
      (lib.getExe cfg.package)
      "serve"
      "--disable-telemetry"
      "--config"
      configFile
    ];
  }
  // lib.optionalAttrs (options ? systemd) {
    systemd.service = {
      after = [ "network-online.target" ];
      description = "Ory Oathkeeper authentication gateway";
      unitConfig = lib.optionalAttrs (cfg.environmentFile != null) {
        RequiresMountsFor = [ cfg.environmentFile ];
      };
      preStart = lib.optionalString (cfg.sessionCheckUrl == null || cfg.upstreamUrl == null) ''
        ${lib.optionalString (cfg.sessionCheckUrl == null) ''
          : "''${${sessionCheckUrlEnv}:?${sessionCheckUrlEnv} is required}"
          session_check_url_pattern=${lib.escapeShellArg sessionCheckUrlPattern}
          if [[ ! "''${${sessionCheckUrlEnv}}" =~ $session_check_url_pattern ]]; then
            echo "${sessionCheckUrlEnv} must use HTTPS or loopback HTTP" >&2
            exit 1
          fi
        ''}
        ${lib.optionalString (cfg.upstreamUrl == null) ''
          : "''${${upstreamUrlEnv}:?${upstreamUrlEnv} is required}"
          umask 0077
          ${pkgs.gettext}/bin/envsubst '${"$"}${upstreamUrlEnv}' < ${rulesFile} > ${runtimeRulesFile}
        ''}
      '';
      restartTriggers = [
        configFile
        rulesFile
      ];
      serviceConfig = {
        AmbientCapabilities = "";
        CapabilityBoundingSet = "";
        DevicePolicy = "closed";
        DynamicUser = true;
        LockPersonality = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        Restart = "on-failure";
        RestartSec = "5s";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
      }
      // lib.optionalAttrs (cfg.upstreamUrl == null) {
        RuntimeDirectory = "oathkeeper";
      }
      // lib.optionalAttrs (cfg.environmentFile != null) {
        EnvironmentFile = cfg.environmentFile;
      };
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
    };
  };
}
