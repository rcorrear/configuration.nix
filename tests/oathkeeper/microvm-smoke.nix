{
  fixture,
  microvmHostModule,
  mkOathkeeperMicrovm,
  nixosSystem,
  mkOathkeeperMicrovmModule,
  pkgs,
}:
let
  environmentFile = "/run/oathkeeper-secrets/environment";
  secretsDirectory = "oathkeeper-secrets";
  sessionCheckUrl = "https://10.0.2.2:18443/sessions/whoami";
  upstreamUrl = "http://10.0.2.2:18081";
  host = nixosSystem {
    inherit (pkgs.stdenv.hostPlatform) system;
    modules = [
      microvmHostModule
      {
        microvm.vms.oathkeeper.config = mkOathkeeperMicrovmModule {
          inherit sessionCheckUrl upstreamUrl;
        };
      }
    ];
  };
  hostRunner = host.config.microvm.vms.oathkeeper.config.config.microvm.declaredRunner;
  production = mkOathkeeperMicrovm {
    inherit sessionCheckUrl upstreamUrl;
    inherit (pkgs.stdenv.hostPlatform) system;
  };
  tcgCpu = if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then "qemu64" else "cortex-a53";
  tcgModule = {
    microvm = {
      cpu = tcgCpu;
    }
    // pkgs.lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
      # QEMU's microvm machine stalls before init under TCG; q35 boots the same guest configuration.
      qemu.machine = "q35";
    };
  };
  runtimeEnvironmentModule = {
    microvm.shares = [
      {
        mountPoint = builtins.dirOf environmentFile;
        proto = "virtiofs";
        readOnly = true;
        source = secretsDirectory;
        tag = "oathkeeper-secrets";
      }
    ];
    systemd.services.oathkeeper-share-readonly = {
      before = [ "oathkeeper.service" ];
      requiredBy = [ "oathkeeper.service" ];
      unitConfig.RequiresMountsFor = [ (builtins.dirOf environmentFile) ];
      serviceConfig.Type = "oneshot";
      script = ''
        test -r ${environmentFile}
        # Even a guest root remount must not bypass virtiofsd's read-only export.
        ${pkgs.util-linux}/bin/mount -o remount,rw ${builtins.dirOf environmentFile} || true
        if touch ${builtins.dirOf environmentFile}/guest-write-probe ||
          printf '%s\n' 'guest modification' >> ${environmentFile}; then
          echo "Guest can modify host secrets" >&2
          exit 1
        fi
      '';
    };
  };
  tcg = mkOathkeeperMicrovm {
    inherit environmentFile;
    extraModules = [
      runtimeEnvironmentModule
      tcgModule
    ];
    inherit (pkgs.stdenv.hostPlatform) system;
    sessionCheckUrl = null;
    upstreamUrl = null;
  };
in
pkgs.runCommandLocal "oathkeeper-microvm-smoke"
  {
    nativeBuildInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.nginx
      pkgs.openssl
      fixture
      tcg.config.microvm.declaredRunner
    ];
  }
  ''
    set -euo pipefail

    grep -F -- '-enable-kvm' ${production.config.microvm.declaredRunner}/bin/microvm-run >/dev/null

    secrets_dir="$PWD/${secretsDirectory}"
    tls_dir="$PWD/oathkeeper-tls"
    mkdir -p "$secrets_dir" "$tls_dir"

    openssl req -x509 -newkey rsa:2048 -nodes \
      -subj '/CN=Oathkeeper smoke test CA' \
      -keyout "$tls_dir/ca.key" \
      -out "$secrets_dir/ca.crt" \
      -days 1
    openssl req -newkey rsa:2048 -nodes \
      -subj '/CN=10.0.2.2' \
      -addext 'subjectAltName=IP:10.0.2.2,IP:127.0.0.1' \
      -keyout "$tls_dir/server.key" \
      -out "$tls_dir/server.csr"
    printf '%s\n' \
      'subjectAltName=IP:10.0.2.2,IP:127.0.0.1' \
      'extendedKeyUsage=serverAuth' \
      > "$tls_dir/server.ext"
    openssl x509 -req \
      -in "$tls_dir/server.csr" \
      -CA "$secrets_dir/ca.crt" \
      -CAkey "$tls_dir/ca.key" \
      -CAcreateserial \
      -extfile "$tls_dir/server.ext" \
      -out "$tls_dir/server.crt" \
      -days 1

    printf '%s\n' \
      'AUTHENTICATORS_COOKIE_SESSION_CONFIG_CHECK_SESSION_URL=${sessionCheckUrl}' \
      'OMNI_OATHKEEPER_UPSTREAM_URL=${upstreamUrl}' \
      'SSL_CERT_FILE=${builtins.dirOf environmentFile}/ca.crt' \
      > "$secrets_dir/environment"
    chmod 0400 "$secrets_dir/environment"

    nginx_config="$tls_dir/nginx.conf"
    cat > "$nginx_config" <<EOF
    daemon off;
    error_log stderr;
    pid $tls_dir/nginx.pid;
    events {}
    http {
      access_log off;
      server {
        listen 18443 ssl;
        ssl_certificate $tls_dir/server.crt;
        ssl_certificate_key $tls_dir/server.key;
        proxy_intercept_errors on;
        error_page 502 504 = @unavailable;
        location / {
          proxy_pass http://127.0.0.1:18080;
        }
        location @unavailable {
          return 444;
        }
      }
    }
    EOF

    nginx -c "$nginx_config" >"$tls_dir/nginx.log" 2>&1 &
    nginx_pid=$!

    virtiofsd_log="$TMPDIR/oathkeeper-virtiofsd.log"
    ${tcg.config.microvm.virtiofsd.package}/bin/virtiofsd \
      --cache=auto \
      --sandbox=none \
      --readonly \
      --shared-dir="$secrets_dir" \
      --socket-path=oathkeeper-virtiofs-oathkeeper-secrets.sock \
      >"$virtiofsd_log" 2>&1 &
    virtiofsd_pid=$!
    vm_pid=
    cleanup() {
      if [ -n "$vm_pid" ]; then
        kill "$vm_pid" 2>/dev/null || true
        wait "$vm_pid" 2>/dev/null || true
      fi
      kill "$virtiofsd_pid" 2>/dev/null || true
      wait "$virtiofsd_pid" 2>/dev/null || true
      kill "$nginx_pid" 2>/dev/null || true
      wait "$nginx_pid" 2>/dev/null || true
    }
    trap cleanup EXIT

    tls_ready=
    for _ in {1..100}; do
      if openssl s_client \
        -connect 127.0.0.1:18443 \
        -CAfile "$secrets_dir/ca.crt" \
        -verify_ip 127.0.0.1 \
        -verify_return_error \
        </dev/null >"$tls_dir/client.log" 2>&1; then
        tls_ready=1
        break
      fi
      kill -0 "$nginx_pid" 2>/dev/null || {
        cat "$tls_dir/nginx.log" >&2
        exit 1
      }
      sleep 0.1
    done
    if [ -z "$tls_ready" ]; then
      cat "$tls_dir/client.log" >&2
      cat "$tls_dir/nginx.log" >&2
      exit 1
    fi

    for _ in {1..100}; do
      [ -S oathkeeper-virtiofs-oathkeeper-secrets.sock ] && break
      sleep 0.1
    done
    if [ ! -S oathkeeper-virtiofs-oathkeeper-secrets.sock ]; then
      cat "$virtiofsd_log" >&2
      exit 1
    fi

    vm_log="$TMPDIR/oathkeeper-microvm.log"
    ${tcg.config.microvm.declaredRunner}/bin/microvm-run >"$vm_log" 2>&1 &
    vm_pid=$!

    test -x ${hostRunner}/bin/microvm-run
    deadline=$(( $(date +%s) + 180 ))
    while true; do
      status="$(curl --max-time 1 --output /dev/null --silent --write-out '%{http_code}' http://127.0.0.1:4455/api/smoke || true)"
      if [ "$status" != 000 ]; then
        break
      fi
      if ! kill -0 "$vm_pid" 2>/dev/null; then
        cat "$vm_log" >&2
        exit 1
      fi
      if [ "$(date +%s)" -ge "$deadline" ]; then
        cat "$vm_log" >&2
        exit 1
      fi
      sleep 0.2
    done

    fixture_output="$(oathkeeper-smoke-fixture)"
    printf '%s\n' "$fixture_output"
    for expected in \
      'valid: status=200 upstream-delta=1' \
      'invalid: status=401 upstream-delta=0' \
      'unverified: status=200 upstream-delta=1' \
      'timeout: status= upstream-delta=0' \
      'stopped-endpoint: status=403 upstream-delta=0'; do
      grep -F -- "$expected" <<<"$fixture_output" >/dev/null
    done

    test ! -e "$secrets_dir/guest-write-probe"
    if grep -F 'guest modification' "$secrets_dir/environment"; then
      exit 1
    fi
    mkdir "$out"
  ''
