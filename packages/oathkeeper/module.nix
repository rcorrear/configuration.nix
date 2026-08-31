{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.omni.oathkeeper;
in
{
  options.services.omni.oathkeeper = {
    enable = lib.mkEnableOption "Omni Oathkeeper authentication gateway";
    environmentFile = lib.mkOption {
      default = null;
      description = "Runtime environment file read by the Oathkeeper service.";
      type = lib.types.nullOr lib.types.str;
    };
    package = lib.mkPackageOption pkgs "oathkeeper" { };
    sessionCheckUrl = lib.mkOption {
      description = "Exact Ory /sessions/whoami URL over HTTPS or loopback HTTP, or null to read it from the environment.";
      type = lib.types.nullOr (lib.types.strMatching (import ./session-check-url.nix));
    };
    upstreamUrl = lib.mkOption {
      description = "Internal user API URL, or null to read it from the environment.";
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
    openFirewall = lib.mkOption {
      default = false;
      description = "Open Oathkeeper proxy port in host firewall.";
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.optionals cfg.openFirewall [ cfg.proxy.port ];

    system.services.oathkeeper = {
      imports = [ (lib.modules.importApply ./service.nix { inherit pkgs; }) ];
      omni.oathkeeper = {
        inherit (cfg)
          api
          environmentFile
          metrics
          package
          proxy
          sessionCheckUrl
          upstreamUrl
          ;
      };
    };
  };
}
