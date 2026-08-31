{ den, inputs, ... }:
let
  secretDir = "/run/oathkeeper-secrets";
  sessionCheckUrlMarker = "__OATHKEEPER_SESSION_CHECK_URL__";
  upstreamUrlMarker = "__OATHKEEPER_UPSTREAM_URL__";
in
{
  flake-file.inputs = {
    omni.url = "github:rcorrear/omni";
  };

  den.aspects.oathkeeper = {
    includes = [ den.aspects.secretspec ];

    nixos =
      { config, pkgs, ... }:
      {
        imports = [ inputs.omni.nixosModules.microvm-host ];

        services.secretspec = {
          enable = true;
          providers.op = {
            type = "onepassword";
            uri = "onepassword+token://Infrastructure";
            credentialFiles.OP_SERVICE_ACCOUNT_TOKEN = config.services.onepassword-secrets.tokenFile;
            packages = [ pkgs._1password-cli ];
            secrets = {
              oathkeeperSessionCheckHost = {
                description = "Oathkeeper Ory session-check host";
                delivery = "file";
                path = "${secretDir}/session-check-host";
                ref = {
                  item = "oathkeeper";
                  field = "session-check-host";
                };
              };
              oathkeeperUpstreamUrl = {
                description = "Oathkeeper upstream URL";
                delivery = "file";
                path = "${secretDir}/upstream-url";
                ref = {
                  item = "oathkeeper";
                  field = "upstream-url";
                };
              };
            };
          };
        };

        systemd.services."microvm-virtiofsd@oathkeeper" = {
          after = [ "secretspec-secrets.service" ];
          requires = [ "secretspec-secrets.service" ];
        };

        microvm = {
          host.enable = true;
          vms.oathkeeper.config = inputs.omni.lib.mkOathkeeperMicrovmModule {
            sessionCheckUrl = sessionCheckUrlMarker;
            upstreamUrl = upstreamUrlMarker;
            extraModules = [
              (
                { config, lib, pkgs, ... }:
                let
                  oathkeeper = config.services.omni.oathkeeper;
                  prepareConfig = pkgs.writeShellScript "prepare-oathkeeper-config" ''
                    set -euo pipefail

                    config_file="$(${pkgs.gnugrep}/bin/grep -l -m1 ${lib.escapeShellArg sessionCheckUrlMarker} /nix/store/*-oathkeeper-config.yaml)"
                    rules_file="$(${pkgs.gnugrep}/bin/grep -l -m1 ${lib.escapeShellArg upstreamUrlMarker} /nix/store/*-oathkeeper-rules.yaml)"
                    session_check_host="$(${pkgs.coreutils}/bin/cat ${lib.escapeShellArg "${secretDir}/session-check-host"})"
                    upstream_url="$(${pkgs.coreutils}/bin/cat ${lib.escapeShellArg "${secretDir}/upstream-url"})"
                    runtime_config=/run/oathkeeper/config.yaml
                    runtime_rules=/run/oathkeeper/rules.yaml

                    config_content="$(${pkgs.coreutils}/bin/cat "$config_file")"
                    config_content="''${config_content//${sessionCheckUrlMarker}/https://$session_check_host/sessions/whoami}"
                    config_content="''${config_content//file://$rules_file/file://$runtime_rules}"
                    printf '%s\n' "$config_content" > "$runtime_config"

                    rules_content="$(${pkgs.coreutils}/bin/cat "$rules_file")"
                    rules_content="''${rules_content//${upstreamUrlMarker}/$upstream_url}"
                    printf '%s\n' "$rules_content" > "$runtime_rules"
                  '';
                in
                {
                  microvm.shares = [
                    {
                      mountPoint = secretDir;
                      proto = "virtiofs";
                      source = secretDir;
                      tag = "oathkeeper-secrets";
                    }
                  ];

                  systemd.services.oathkeeper-config = {
                    before = [ "oathkeeper.service" ];
                    serviceConfig = {
                      RequiresMountsFor = [ secretDir ];
                      RemainAfterExit = true;
                      RuntimeDirectory = "oathkeeper";
                      Type = "oneshot";
                    };
                    script = prepareConfig;
                  };

                  systemd.services.oathkeeper = {
                    after = [ "oathkeeper-config.service" ];
                    requires = [ "oathkeeper-config.service" ];
                    serviceConfig.ExecStart = lib.mkForce [
                      (lib.getExe oathkeeper.package)
                      "serve"
                      "--disable-telemetry"
                      "--config"
                      "/run/oathkeeper/config.yaml"
                    ];
                  };
                }
              )
            ];
          };
          autostart = [ "oathkeeper" ];
        };
      };
  };
}
