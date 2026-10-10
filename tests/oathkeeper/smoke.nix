{
  fixture,
  oathkeeperModule,
  pkgs,
}:
let
  inherit (pkgs) lib;
  secretDir = "/run/oathkeeper-inputs";
  sessionCheckUrlMarker = "https://__OATHKEEPER_SESSION_CHECK_URL__/sessions/whoami";
  upstreamUrlMarker = "__OATHKEEPER_UPSTREAM_URL__";
  acceptedSessionCheckUrls = [
    "https://auth.example.test/sessions/whoami"
    "https://10.0.2.2:18443/sessions/whoami"
    "http://localhost:18080/sessions/whoami"
    "http://127.0.0.1:18080/sessions/whoami"
    "http://[::1]:18080/sessions/whoami"
  ];
  rejectedSessionCheckUrls = [
    "http://auth.example.test/sessions/whoami"
    "http://10.0.2.2:18080/sessions/whoami"
    "http://localhost.example.test/sessions/whoami"
    "http://127.0.0.1@auth.example.test/sessions/whoami"
    "http://[::1]@auth.example.test/sessions/whoami"
    "http://127.0.0.1:18080.evil/sessions/whoami"
    "ftp://auth.example.test/sessions/whoami"
    ""
  ];
  sessionCheckUrlTypes = [
    (lib.evalModules {
      modules = [
        oathkeeperModule
        { _module.check = false; }
      ];
    }).options.services.omni.oathkeeper.sessionCheckUrl.type
    (lib.evalModules {
      class = "service";
      modules = [
        (lib.modules.importApply ../../packages/oathkeeper/service.nix { inherit pkgs; })
        { _module.check = false; }
      ];
    }).options.omni.oathkeeper.sessionCheckUrl.type
  ];
in
assert lib.all (
  type:
  type.check null
  && lib.all type.check acceptedSessionCheckUrls
  && lib.all (url: !type.check url) rejectedSessionCheckUrls
) sessionCheckUrlTypes;
{
  name = "oathkeeper-smoke";
  globalTimeout = 300;
  requiredFeatures.kvm = false;

  nodes = {
    machine =
      { ... }:
      {
        imports = [ oathkeeperModule ];

        environment.systemPackages = [
          fixture
          pkgs.iproute2
        ];

        systemd.services.oathkeeper-environment = {
          before = [ "oathkeeper.service" ];
          requiredBy = [ "oathkeeper.service" ];
          script = ''
            install -m 0400 /dev/null /run/oathkeeper.env
            printf '%s\n' \
              'AUTHENTICATORS_COOKIE_SESSION_CONFIG_CHECK_SESSION_URL=http://127.0.0.1:1/wrong' \
              'OMNI_OATHKEEPER_UPSTREAM_URL=http://127.0.0.1:18081' \
              > /run/oathkeeper.env
          '';
          serviceConfig = {
            RemainAfterExit = true;
            Type = "oneshot";
          };
        };

        services.omni.oathkeeper = {
          enable = true;
          environmentFile = "/run/oathkeeper.env";
          sessionCheckUrl = "http://127.0.0.1:18080/sessions/whoami";
          upstreamUrl = null;
          proxy.host = "127.0.0.1";
          api.host = "127.0.0.1";
          metrics.host = "127.0.0.1";
        };
      };

    runtime =
      { lib, ... }:
      {
        imports = [ oathkeeperModule ];

        services.omni.oathkeeper = {
          enable = true;
          environmentFile = "/run/oathkeeper-runtime.env";
          sessionCheckUrl = null;
          upstreamUrl = "http://127.0.0.1:18081";
        };
        systemd.services.oathkeeper = {
          wantedBy = lib.mkForce [ ];
          serviceConfig.Restart = lib.mkForce "no";
        };
      };

    credentials = {
      imports = [
        oathkeeperModule
        (import ../../packages/oathkeeper/runtime-secrets.nix {
          inherit secretDir sessionCheckUrlMarker upstreamUrlMarker;
        })
      ];

      services.omni.oathkeeper = {
        enable = true;
        sessionCheckUrl = sessionCheckUrlMarker;
        upstreamUrl = upstreamUrlMarker;
        proxy.host = "127.0.0.1";
      };
      users.users.unrelated.isNormalUser = true;

      # Matching decoys must not affect selection of the generated files.
      system.extraDependencies = [
        (pkgs.writeText "oathkeeper-config.yaml" "decoy: ${sessionCheckUrlMarker}")
        (pkgs.writeText "oathkeeper-rules.yaml" "decoy: ${upstreamUrlMarker}")
      ];
      systemd.services.oathkeeper-inputs = {
        before = [ "oathkeeper.service" ];
        requiredBy = [ "oathkeeper.service" ];
        serviceConfig = {
          RemainAfterExit = true;
          Type = "oneshot";
          UMask = "0077";
        };
        script = ''
          install -d -m 0700 ${secretDir}
          printf '%s\n' 'auth.example.test' > ${secretDir}/session-check-host
          printf '%s\n' 'http://127.0.0.1:18081' > ${secretDir}/upstream-url
          chmod 0400 ${secretDir}/*
        '';
      };
    };
  };

  testScript = ''
    import shlex

    start_all()
    credentials.wait_for_unit("oathkeeper.service")
    credentials.succeed("grep -F 'https://auth.example.test/sessions/whoami' /run/oathkeeper/config.yaml")
    credentials.succeed("grep -F 'file:///run/oathkeeper/rules.yaml' /run/oathkeeper/config.yaml")
    credentials.succeed("grep -F 'http://127.0.0.1:18081' /run/oathkeeper/rules.yaml")
    credentials.fail("grep -F 'decoy:' /run/oathkeeper/config.yaml /run/oathkeeper/rules.yaml")
    assert credentials.succeed("stat -L --format=%a /run/oathkeeper").strip() == "700"
    for path in ["/run/oathkeeper/config.yaml", "/run/oathkeeper/rules.yaml"]:
      assert credentials.succeed("stat --format=%a " + path).strip() == "600"
      assert credentials.succeed("stat --format=%U " + path).strip() == "oathkeeper"
      credentials.fail("runuser -u unrelated -- cat " + path)
    upstream_url = "http://127.0.0.1:4200/api?first=1&second=two&empty="
    credentials.succeed("printf '%s\\n' " + shlex.quote(upstream_url) + " > ${secretDir}/upstream-url")
    credentials.succeed("systemctl restart oathkeeper.service")
    credentials.wait_for_unit("oathkeeper.service")
    credentials.succeed("grep -F " + shlex.quote(upstream_url) + " /run/oathkeeper/rules.yaml")
    credentials.fail("grep -F '${upstreamUrlMarker}' /run/oathkeeper/rules.yaml")
    credentials.succeed("systemctl stop oathkeeper.service")
    credentials.succeed("test ! -e /run/oathkeeper/config.yaml")
    credentials.succeed("rm ${secretDir}/upstream-url")
    credentials.fail("systemctl start oathkeeper.service")
    credentials.succeed("test ! -e /run/oathkeeper/config.yaml")

    machine.wait_for_unit("oathkeeper.service")
    assert machine.succeed("systemctl is-active oathkeeper.service").strip() == "active"
    assert machine.succeed("systemctl show oathkeeper.service --property=DynamicUser --value").strip() == "yes"
    assert machine.succeed("stat --format=%a /run/oathkeeper/rules.yaml").strip() == "600"
    machine.wait_until_succeeds("ss -ltn | grep -F '127.0.0.1:4455'")
    machine.wait_until_succeeds("ss -ltn | grep -F '127.0.0.1:4456'")
    machine.wait_until_succeeds("ss -ltn | grep -F '127.0.0.1:9000'")
    output = machine.succeed("oathkeeper-smoke-fixture")
    print(output)
    for expected in [
      "valid: status=200 upstream-delta=1",
      "invalid: status=401 upstream-delta=0",
      "unverified: status=200 upstream-delta=1",
      "timeout: status= upstream-delta=0",
      "stopped-endpoint: status=403 upstream-delta=0",
    ]:
      assert expected in output, output
    machine.succeed("systemctl stop oathkeeper.service")
    machine.succeed("truncate --size 0 /run/oathkeeper.env")
    machine.fail("systemctl start oathkeeper.service")

    for url in ${builtins.toJSON acceptedSessionCheckUrls}:
      runtime.succeed("printf '%s\\n' " + shlex.quote("AUTHENTICATORS_COOKIE_SESSION_CONFIG_CHECK_SESSION_URL=" + url) + " > /run/oathkeeper-runtime.env")
      runtime.succeed("systemctl reset-failed")
      runtime.succeed("systemctl start oathkeeper.service")
      runtime.wait_for_unit("oathkeeper.service")
      runtime.succeed("systemctl stop oathkeeper.service")

    for url in ${builtins.toJSON rejectedSessionCheckUrls}:
      runtime.succeed("printf '%s\\n' " + shlex.quote("AUTHENTICATORS_COOKIE_SESSION_CONFIG_CHECK_SESSION_URL=" + url) + " > /run/oathkeeper-runtime.env")
      runtime.succeed("systemctl reset-failed")
      runtime.fail("systemctl start oathkeeper.service")
      assert runtime.succeed("systemctl show oathkeeper.service --property=MainPID --value").strip() == "0"
      if url:
        runtime.succeed("journalctl -u oathkeeper.service --no-pager | grep -F 'must use HTTPS or loopback HTTP'")
  '';
}
