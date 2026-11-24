{ pkgs, secretspec }:
let
  mockOp = pkgs.writeScriptBin "op" ''
    #!${pkgs.python3}/bin/python3
    import os, re, sys
    assert os.getuid() == 0
    assert os.environ["OP_SERVICE_ACCOUNT_TOKEN"] == "dummy-bootstrap-token"
    if os.environ.get("MOCK_FAILURE") == "auth":
        sys.exit(1)
    if sys.argv[1:3] == ["vault", "list"]:
        print('[{"id":"test","name":"Infrastructure"}]')
    elif sys.argv[1] == "inject":
        values = {
            "initial-password": "dummy password ' $ punctuation",
            "jwt-secret": "dummy-jwt",
            "api-key-secret": "dummy-api",
            "machine-id-salt": "dummy-salt",
        }
        if os.environ.get("MOCK_FAILURE") == "field":
            sys.exit(1)
        def replace(match):
            reference = match.group(1).strip()
            assert reference.startswith("Infrastructure/9router/"), reference
            field = reference.split("/")[-1]
            return values[field]
        print(re.sub(r"\{\{\s*op://(.*?)\s*\}\}", replace, sys.stdin.read()), end="")
    else:
        sys.exit(1)
  '';
  runtime = import ../../packages/9router/secretspec.nix {
    inherit pkgs secretspec;
    onepasswordCli = mockOp;
    secretsDir = "/run/9router-test-secrets";
  };
  app = pkgs.writeScript "9router-test-app" ''
    #!${pkgs.python3}/bin/python3
    import os, pathlib
    os.chdir("/tmp/9router-tests")
    assert os.getuid() == os.geteuid() == 1000
    assert os.getgid() == os.getegid() == 1000
    assert os.getgroups() == []
    status = dict(line.split(":", 1) for line in pathlib.Path("/proc/self/status").read_text().splitlines())
    for cap in ["CapInh", "CapPrm", "CapEff", "CapBnd", "CapAmb"]:
        assert int(status[cap].strip(), 16) == 0, (cap, status[cap])
    assert status["NoNewPrivs"].strip() == "1"
    try:
        pathlib.Path("/run/9router-test-secrets/onepassword-token").read_text()
    except PermissionError:
        pass
    else:
        raise AssertionError("Application can read bootstrap token")
    assert os.environ["INITIAL_PASSWORD"] == "dummy password ' $ punctuation"
    assert os.environ["JWT_SECRET"] == "dummy-jwt"
    assert os.environ["API_KEY_SECRET"] == "dummy-api"
    assert os.environ["MACHINE_ID_SALT"] == "dummy-salt"
    assert "OP_SERVICE_ACCOUNT_TOKEN" not in os.environ
    pathlib.Path("started").touch()
  '';
  longApp = pkgs.writeScript "9router-test-signal" ''
    #!${pkgs.python3}/bin/python3
    import pathlib, signal, sys
    import os
    os.chdir("/tmp/9router-tests")
    def stop(*_):
        pathlib.Path("stopped").touch()
        sys.exit(0)
    signal.signal(signal.SIGTERM, stop)
    pathlib.Path("ready").touch()
    signal.pause()
  '';
in
{
  inherit mockOp;
  testScript = pkgs.writeShellScript "9router-secretspec-test" ''
    set -euo pipefail
    export PATH=${
      pkgs.lib.makeBinPath [
        pkgs.coreutils
        pkgs.gnugrep
        pkgs.findutils
      ]
    }
    mkdir -m 0700 /run/9router-test-secrets
    printf %s dummy-bootstrap-token > /run/9router-test-secrets/onepassword-token
    chmod 0400 /run/9router-test-secrets/onepassword-token
    mkdir -m 0777 /tmp/9router-tests
    cd /tmp/9router-tests
    # The separately running Nimi smoke service owns one live resolver directory.
    before="$(find /tmp -maxdepth 1 -name '9router-secretspec.*' -print | sort)"
    # A parent token must not leak into the child or override the file credential.
    export OP_SERVICE_ACCOUNT_TOKEN=wrong-ambient-token
    ${pkgs.lib.getExe runtime.launcher} ${app} > success.log 2>&1 || { cat success.log; exit 1; }
    test -f started
    rm started
    # Misprovisioned ownership/modes must not silently remove the boundary.
    chmod 0644 /run/9router-test-secrets/onepassword-token
    if ${pkgs.lib.getExe runtime.launcher} ${app} > permissions.log 2>&1; then
      echo "World-readable token must fail closed"; exit 1
    fi
    chmod 0400 /run/9router-test-secrets/onepassword-token
    chmod 0755 /run/9router-test-secrets
    if ${pkgs.lib.getExe runtime.launcher} ${app} > permissions.log 2>&1; then
      echo "Non-private directory must fail closed"; exit 1
    fi
    chmod 0700 /run/9router-test-secrets
    if ${pkgs.util-linux}/bin/setpriv --reuid=1000 --regid=1000 --clear-groups \
        -- ${pkgs.lib.getExe runtime.launcher} ${app} > unprivileged.log 2>&1; then
      echo "An application user must not invoke a privileged resolver"; exit 1
    fi
    test ! -e started
    for failure in auth field; do
      if MOCK_FAILURE="$failure" ${pkgs.lib.getExe runtime.launcher} ${app} > failure.log 2>&1; then
        echo "Expected $failure to fail closed"; exit 1
      fi
      test ! -e started
      if grep -qE 'dummy-bootstrap-token|dummy-jwt|dummy-api|dummy-salt' failure.log; then
        echo "Failure log leaked a fixture secret"; exit 1
      fi
    done
    rm /run/9router-test-secrets/onepassword-token
    if ${pkgs.lib.getExe runtime.launcher} ${app} > missing.log 2>&1; then
      echo "Missing token must fail closed"; exit 1
    fi
    test ! -e started
    # Preserve child exit status rather than swallowing failed application starts.
    printf %s dummy-bootstrap-token > /run/9router-test-secrets/onepassword-token
    chmod 0400 /run/9router-test-secrets/onepassword-token
    status=0
    ${pkgs.lib.getExe runtime.launcher} ${pkgs.bash}/bin/bash -c 'exit 23' > exit.log 2>&1 || status=$?
    test "$status" = 23
    # TERM must cross both the launcher and SecretSpec and reach the application.
    ${pkgs.lib.getExe runtime.launcher} ${longApp} > signal.log 2>&1 &
    launcher=$!
    trap 'kill "$launcher" 2>/dev/null || true' EXIT
    for attempt in $(seq 1 100); do
      if test -f ready; then break; fi
      sleep 0.1
    done
    test -f ready
    kill -TERM "$launcher"
    wait "$launcher" || true
    test -f stopped
    trap - EXIT
    remaining="$(find /tmp -maxdepth 1 -name '9router-secretspec.*' -print | sort)"
    test "$remaining" = "$before"
  '';
}
