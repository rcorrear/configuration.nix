{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services."9router";
  stateDir = "/var/lib/9router";
in
{
  options.services."9router" = with lib; {
    enable = mkEnableOption "9Router server";

    package = mkOption {
      type = types.package;
      default = pkgs.rcorrear."9router";
      description = "The 9Router package to run.";
    };

    address = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Address on which 9Router listens.";
    };

    port = mkOption {
      type = types.port;
      default = 20128;
      description = "TCP port on which 9Router listens.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Open the 9Router TCP port in the firewall.";
    };

    requireApiKey = mkOption {
      type = types.bool;
      default = true;
      description = "Require API keys for gateway requests.";
    };

    environmentFiles = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Environment files read by the 9Router service.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.environmentFiles != [ ];
        message = "services.9router.environmentFiles must contain at least one file when 9Router is enabled";
      }
    ];

    networking.firewall.allowedTCPPorts = lib.optional cfg.openFirewall cfg.port;

    systemd.services."9router" = {
      description = "9Router server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      environment = {
        DATA_DIR = stateDir;
        HOSTNAME = cfg.address;
        MITM_SERVER_PATH = "${cfg.package}/lib/9router/app/src/mitm/server.js";
        PORT = toString cfg.port;
        REQUIRE_API_KEY = lib.boolToString cfg.requireApiKey;
      };
      serviceConfig = {
        DynamicUser = true;
        StateDirectory = "9router";
        EnvironmentFile = cfg.environmentFiles;
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
      };
    };
  };
}
