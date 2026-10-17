state="$(mktemp -d)"
trap 'rm -rf "$state"' EXIT
mkdir -p "$state/data"
cat >"$state/secrets.env" <<'EOF'
INITIAL_PASSWORD=smoke-test-only
JWT_SECRET=smoke-test-only-jwt-not-production
API_KEY_SECRET=smoke-test-only-api-not-production
MACHINE_ID_SALT=smoke-test-only-salt-not-production
EOF
printf %s dummy-bootstrap-token >"$state/onepassword-token"

# No external network, host services, credentials, or gateway state are exposed.
# Variables in the inner script must expand inside the isolated shell.
# shellcheck disable=SC2016
bwrap --unshare-all --die-with-parent \
  --ro-bind /nix/store /nix/store \
  --proc /proc --dev /dev --tmpfs /tmp \
  --dir /run/secrets --ro-bind "$state/secrets.env" /run/secrets/9router.env \
  --ro-bind "$state/onepassword-token" /run/secrets/onepassword-token \
  --dir /var/lib --bind "$state/data" /var/lib/9router \
  --setenv HOME /var/lib/9router \
  bash -euo pipefail -c '
    "$NINE_ROUTER_RUNNER" > /tmp/9router.log 2>&1 &
    pid=$!
    trap '\''kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true'\'' EXIT
    ready=false
    for attempt in {1..30}; do
      if status="$(curl --silent --max-time 2 --output /tmp/login \
        --write-out "%{http_code}" http://127.0.0.1:20128/login)"; then
        if [ "$status" = 200 ]; then
          ready=true
          break
        fi
      fi
      sleep 1
    done
    if [ "$ready" != true ]; then
      cat /tmp/9router.log
      echo "9Router did not serve its login page" >&2
      exit 1
    fi
    destination="$(curl --silent --location --max-time 5 --output /tmp/dashboard \
      --write-out "%{url_effective}" http://127.0.0.1:20128/dashboard)"
    case "$destination" in
      */login|*/login\?*) ;;
      *)
        echo "Unauthenticated dashboard did not redirect to login: $destination" >&2
        exit 1
        ;;
    esac
    status="$(curl --silent --max-time 5 --output /tmp/completion \
      --header "Content-Type: application/json" \
      --data '\''{"model":"smoke-test","messages":[{"role":"user","content":"test"}]}'\'' \
      --write-out "%{http_code}" http://127.0.0.1:20128/v1/chat/completions)"
    if [ "$status" != 401 ] && [ "$status" != 403 ]; then
      cat /tmp/9router.log
      echo "Expected API-key rejection, got HTTP $status" >&2
      exit 1
    fi
    echo "9Router login: HTTP 200; unauthenticated API: HTTP $status"
  '
