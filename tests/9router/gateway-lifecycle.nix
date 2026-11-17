{ pkgs, gatewayModule }:
let
  tailscale = pkgs.writeShellApplication {
    name = "tailscale";
    text = ''
      exec ${pkgs.python3}/bin/python3 ${./mock-tailscale.py} "$@"
    '';
  };
  # Exercise the actual legacy aspect's Serve unit without its unrelated
  # application/secret provisioning modules or a tailnet login.
  legacy =
    (import ../../modules/aspects/9router/default.nix {
      den.aspects.secretspec = { };
    }).den.aspects."9router-service".nixos
      {
        inherit pkgs;
        config.services = {
          tailscale.package = tailscale;
          "9router".port = 20128;
        };
      };
in
pkgs.testers.runNixOSTest {
  name = "tailscale-service-gateway-lifecycle";
  nodes.machine = {
    imports = [ gatewayModule ];
    virtualisation.memorySize = 1024;
    services.tailscale.package = tailscale;
    services.tailscaleServiceGateway = {
      enable = true;
      services = {
        first.backend = "http://192.0.2.10:20128";
        second.backend = "http://192.0.2.11:8080";
      };
    };
    systemd = {
      tmpfiles.rules = [ "d /run/mock-tailscale 0700 root root -" ];
      services = {
        # A fake daemon provides real systemd lifecycle/ordering without contacting
        # Tailscale. Its marker verifies CLI calls never occur after shutdown.
        tailscaled.serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.coreutils}/bin/touch /run/mock-tailscale/alive";
          ExecStop = "${pkgs.coreutils}/bin/rm /run/mock-tailscale/alive";
        };
        "9router".serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.coreutils}/bin/true";
        };
        "9router-tailscale" = legacy.systemd.services."9router-tailscale";
      };
    };
  };
  testScript = ''
    import json

    named = ["tailscale-svc-first.service", "tailscale-svc-second.service"]
    units = named + ["9router-tailscale.service"]

    def state():
        return json.loads(machine.succeed("cat /run/mock-tailscale/state.json"))

    def ready():
        for unit in units:
            machine.wait_for_unit(unit, timeout=30)
        current = state()
        assert current["advertised"] == ["svc:first", "svc:second"], current
        assert current["services"] == {
            "svc:first": "http://192.0.2.10:20128",
            "svc:second": "http://192.0.2.11:8080",
        }, current
        assert current["node"], current
        machine.fail("test -e /run/mock-tailscale/overlap")

    start_all()
    machine.wait_for_unit("multi-user.target")
    ready()

    # Start and stop both named units in one systemd transaction, repeatedly.
    # Scoped cleanup must preserve the ordinary node-level Serve configuration.
    for _ in range(3):
        machine.succeed("systemctl stop " + " ".join(named))
        assert state() == {"advertised": [], "services": {}, "node": True}
        machine.succeed("systemctl start " + " ".join(named))
        ready()

    # PartOf stops dependents; tailscaled's Wants must start them again.
    machine.succeed("systemctl stop tailscaled.service")
    for unit in units:
        machine.fail("systemctl is-active --quiet " + unit)
    assert state() == {"advertised": [], "services": {}, "node": False}
    machine.succeed("systemctl start tailscaled.service")
    ready()
    machine.succeed("systemctl restart tailscaled.service")
    ready()

    # The legacy unit follows its application through stop/start as well.
    machine.succeed("systemctl stop 9router.service")
    machine.fail("systemctl is-active --quiet 9router-tailscale.service")
    assert not state()["node"]
    assert state()["advertised"] == ["svc:first", "svc:second"]
    machine.succeed("systemctl start 9router.service")
    ready()
  '';
}
