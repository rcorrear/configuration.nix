{
  config,
  lib,
  ...
}:
let
  cfg = config.services.tailscaleServiceGateway;
  tailscale = lib.getExe config.services.tailscale.package;
in
{
  options.services.tailscaleServiceGateway = {
    enable = lib.mkEnableOption "named Tailscale Services forwarding to private application backends";
    services = lib.mkOption {
      default = { };
      description = "Service names without svc:, mapped to their private HTTP(S) backend URL.";
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.backend = lib.mkOption {
            type = lib.types.strMatching "https?://[^[:space:]]+";
            description = "Stable private backend URL. Restrict direct access with a firewall.";
          };
        }
      );
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.services != { };
        message = "tailscaleServiceGateway requires at least one service.";
      }
      {
        assertion = lib.all (
          name:
          builtins.stringLength name <= 63 && builtins.match "[a-z0-9]([a-z0-9-]*[a-z0-9])?" name != null
        ) (builtins.attrNames cfg.services);
        message = "tailscaleServiceGateway service names must be lowercase DNS labels.";
      }
    ];

    services.tailscale.enable = true;
    # Use the CLI until declarative Services support HTTPS -> HTTP correctly.
    # See docs/9router.md for upstream tracking PRs. Never reset unrelated Serve state.
    systemd.services = lib.mapAttrs' (
      name: service:
      lib.nameValuePair "tailscale-svc-${name}" {
        description = "Tailscale Service svc:${name}";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [
          "network-online.target"
          "tailscaled.service"
          "tailscaled-autoconnect.service"
          "tailscaled-set.service"
        ];
        requires = [ "tailscaled.service" ];
        partOf = [ "tailscaled.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          TimeoutStartSec = "30s";
          ExecStart = "${tailscale} ${
            lib.escapeShellArgs [
              "serve"
              "--service=svc:${name}"
              "--bg"
              "--yes"
              "--https=443"
              # systemd interprets percent specifiers even inside quoted arguments.
              (lib.replaceStrings [ "%" ] [ "%%" ] service.backend)
            ]
          }";
          ExecStop = [
            "${tailscale} serve drain svc:${name}"
            "${tailscale} serve clear svc:${name}"
          ];
          Restart = "on-failure";
          RestartSec = "10s";
        };
      }
    ) cfg.services;
  };
}
