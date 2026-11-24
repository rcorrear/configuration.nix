{
  pkgs,
  secretTests,
  runner,
}:
pkgs.testers.runNixOSTest {
  name = "9router-secret-privileges";
  nodes.machine = {
    virtualisation.memorySize = 2048;
    environment.systemPackages = [
      pkgs.curl
      pkgs.procps
    ];
    systemd.services."9router-test" = {
      wantedBy = [ "multi-user.target" ];
      preStart = ''
        install -d -m 0700 -o 1000 -g 1000 /var/lib/9router
        install -d -m 0700 /run/secrets
        printf %s dummy-bootstrap-token > /run/secrets/onepassword-token
        chmod 0400 /run/secrets/onepassword-token
      '';
      serviceConfig = {
        ExecStart = pkgs.lib.getExe runner;
        User = "root";
        WorkingDirectory = "/";
        KillMode = "control-group";
      };
    };
  };
  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")
    machine.wait_until_succeeds("curl -fsS http://127.0.0.1:20128/login > /dev/null")
    machine.succeed("timeout 60 ${secretTests.testScript}")
    machine.succeed("test \"$(curl -s -o /dev/null -w '%{http_code}' -H 'Content-Type: application/json' --data '{}' http://127.0.0.1:20128/v1/chat/completions)\" = 401")
    machine.succeed("curl -s -L -o /dev/null -w '%{url_effective}' http://127.0.0.1:20128/dashboard | grep '/login'")
    # Verify the real Node process, not only the fixture command, is unprivileged.
    node_pid = int(machine.succeed("pgrep -u 1000").strip())
    status = dict(line.split(":", 1) for line in machine.succeed(f"cat /proc/{node_pid}/status").splitlines())
    assert status["Uid"].split() == ["1000"] * 4
    assert status["Gid"].split() == ["1000"] * 4
    assert status["Groups"].strip() == ""
    for cap in ["CapInh", "CapPrm", "CapEff", "CapBnd", "CapAmb"]:
        assert int(status[cap].strip(), 16) == 0, (cap, status[cap])
    assert status["NoNewPrivs"].strip() == "1"
    machine.fail("${pkgs.util-linux}/bin/setpriv --reuid=1000 --regid=1000 --clear-groups -- ${pkgs.coreutils}/bin/cat /run/secrets/onepassword-token")
    machine.succeed("systemctl stop 9router-test")
    machine.fail("pgrep -u 1000")
    machine.succeed("systemctl start 9router-test")
    machine.wait_until_succeeds("curl -fsS http://127.0.0.1:20128/login > /dev/null")
    machine.succeed("systemctl stop 9router-test")
    machine.fail("pgrep -u 1000")
  '';
}
