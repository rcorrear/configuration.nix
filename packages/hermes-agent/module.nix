{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.hermes-agent;

  deepConfigType = lib.types.mkOptionType {
    name = "hermes-config-attrs";
    description = "Hermes config attrset merged deeply via lib.recursiveUpdate.";
    check = builtins.isAttrs;
    merge = _loc: defs: lib.foldl' lib.recursiveUpdate { } (map (d: d.value) defs);
  };

  generatedConfigFile = (pkgs.formats.yaml { }).generate "hermes-config.yaml" cfg.settings;
  envFile = "${cfg.stateDir}/.hermes/.env";
  envFileContent = lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "${k}=${v}") cfg.environment);
in
{
  options.services.hermes-agent = with lib; {
    enable = mkEnableOption "Hermes Agent gateway service";

    package = mkOption {
      type = types.package;
      description = "The hermes-agent package to run.";
    };

    user = mkOption {
      type = types.str;
      default = "hermes";
      description = "System user running Hermes.";
    };

    group = mkOption {
      type = types.str;
      default = "hermes";
      description = "System group running Hermes.";
    };

    createUser = mkOption {
      type = types.bool;
      default = true;
      description = "Create the Hermes user and group automatically.";
    };

    stateDir = mkOption {
      type = types.str;
      default = "/var/lib/hermes";
      description = "State directory used by Hermes.";
    };

    workingDirectory = mkOption {
      type = types.str;
      default = "${cfg.stateDir}/workspace";
      description = "Working directory for Hermes gateway sessions.";
    };

    settings = mkOption {
      type = deepConfigType;
      default = { };
      description = "Declarative Hermes config rendered to config.yaml.";
    };

    environment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Non-secret environment variables merged into .env.";
    };

    environmentFiles = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Secret env files appended to Hermes .env.";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra command-line arguments passed to `hermes gateway`.";
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Extra packages added to the service PATH.";
    };

    restart = mkOption {
      type = types.str;
      default = "always";
      description = "systemd Restart= policy.";
    };

    restartSec = mkOption {
      type = types.int;
      default = 5;
      description = "systemd RestartSec= value.";
    };

    addToSystemPackages = mkOption {
      type = types.bool;
      default = false;
      description = "Expose the Hermes CLI in environment.systemPackages.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups = lib.mkIf cfg.createUser { "${cfg.group}" = { }; };
    users.users = lib.mkIf cfg.createUser {
      "${cfg.user}" = {
        isSystemUser = true;
        group = cfg.group;
        home = cfg.stateDir;
        createHome = true;
        shell = pkgs.bashInteractive;
      };
    };

    environment.systemPackages = lib.optionals cfg.addToSystemPackages [ cfg.package ];

    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0750 ${cfg.user} ${cfg.group} - -"
      "d ${cfg.stateDir}/.hermes 0750 ${cfg.user} ${cfg.group} - -"
      "d ${cfg.workingDirectory} 0750 ${cfg.user} ${cfg.group} - -"
    ];

    system.activationScripts.hermes-agent-setup = lib.stringAfter [ "users" ] ''
      mkdir -p ${cfg.stateDir}/.hermes
      mkdir -p ${cfg.workingDirectory}
      chown ${cfg.user}:${cfg.group} ${cfg.stateDir} ${cfg.stateDir}/.hermes ${cfg.workingDirectory}
      chmod 0750 ${cfg.stateDir} ${cfg.stateDir}/.hermes ${cfg.workingDirectory}

      install -o ${cfg.user} -g ${cfg.group} -m 0640 ${generatedConfigFile} ${cfg.stateDir}/.hermes/config.yaml
    '';

    systemd.services.hermes-agent = {
      description = "Hermes Agent Gateway";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      environment = {
        HOME = cfg.stateDir;
        HERMES_HOME = "${cfg.stateDir}/.hermes";
        HERMES_MANAGED = "true";
        MESSAGING_CWD = cfg.workingDirectory;
      };
      path = [
        cfg.package
        pkgs.bash
        pkgs.coreutils
        pkgs.git
      ]
      ++ cfg.extraPackages;
      preStart = ''
                ENV_FILE=${lib.escapeShellArg envFile}
                umask 0077
                : > "$ENV_FILE"
                cat > "$ENV_FILE" <<'HERMES_ENV_EOF'
        ${envFileContent}
        HERMES_ENV_EOF

                ${lib.concatMapStringsSep "\n" (f: ''
                  if [ -f ${lib.escapeShellArg f} ]; then
                    echo "" >> "$ENV_FILE"
                    cat ${lib.escapeShellArg f} >> "$ENV_FILE"
                  fi
                '') cfg.environmentFiles}
      '';
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.workingDirectory;
        ExecStart = lib.concatStringsSep " " (
          [
            "${cfg.package}/bin/hermes"
            "gateway"
          ]
          ++ cfg.extraArgs
        );
        Restart = cfg.restart;
        RestartSec = cfg.restartSec;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = false;
        ReadWritePaths = [ cfg.stateDir ];
        PrivateTmp = true;
      };
    };
  };
}
