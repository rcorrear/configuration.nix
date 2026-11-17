{
  pkgs,
  nixosSystem,
  gatewayModule,
}:
let
  evaluate =
    services:
    (nixosSystem {
      system = pkgs.stdenv.hostPlatform.system;
      modules = [
        gatewayModule
        {
          system.stateVersion = "26.05";
          services.tailscaleServiceGateway = {
            enable = true;
            inherit services;
          };
        }
      ];
    }).config;
  cfg = evaluate {
    nine-router.backend = "http://192.0.2.10:20128";
    another-app.backend = "http://192.0.2.11:8080/a%20b";
  };
  unit = cfg.systemd.services.tailscale-svc-nine-router.serviceConfig;
  gateway = cfg.systemd.services.tailscale-svc-nine-router;
  empty = evaluate { };
  invalid = evaluate { "INVALID".backend = "http://192.0.2.10:20128"; };
  messages = c: map (a: a.message) (builtins.filter (a: !a.assertion) c.assertions);
in
assert cfg.services.tailscale.enable;
assert builtins.hasAttr "tailscale-svc-another-app" cfg.systemd.services;
assert pkgs.lib.hasInfix "a%%20b"
  cfg.systemd.services.tailscale-svc-another-app.serviceConfig.ExecStart;
assert pkgs.lib.hasInfix "--service=svc:nine-router" unit.ExecStart;
assert pkgs.lib.hasInfix "--https=443" unit.ExecStart;
assert pkgs.lib.hasInfix "http://192.0.2.10:20128" unit.ExecStart;
assert builtins.elem "tailscaled.service" gateway.wantedBy;
assert builtins.elem "tailscaled.service" gateway.after;
assert builtins.elem "tailscaled.service" gateway.partOf;
assert pkgs.lib.all (command: pkgs.lib.hasInfix "/run/lock/tailscale-serve.lock" command) (
  [ unit.ExecStart ] ++ unit.ExecStop
);
assert pkgs.lib.all (command: !(pkgs.lib.hasInfix "reset" command)) unit.ExecStop;
assert !(builtins.elem 443 cfg.networking.firewall.allowedTCPPorts);
assert builtins.elem "tailscaleServiceGateway requires at least one service." (messages empty);
assert builtins.elem "tailscaleServiceGateway service names must be lowercase DNS labels." (
  messages invalid
);
pkgs.runCommand "tailscale-service-gateway-eval" { } ''
  touch "$out"
''
