"""Exercise the packaged app: python3 test-setup.py /nix/store/...-finzytrack."""

import configparser
import json
import os
from pathlib import Path
import signal
import socket
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request


package = Path(sys.argv[1])
desktop = configparser.ConfigParser()
desktop.read(package / "share/applications/finzytrack.desktop")
assert desktop["Desktop Entry"]["Exec"] == "finzytrack"
assert (package / "bin/finzytrack").is_file()
assert (package / "share/icons/hicolor/512x512/apps/finzytrack.png").is_file()

for mode in ("fresh", "demo", "existing"):
    with tempfile.TemporaryDirectory(prefix="finzytrack-test-") as tmp:
        root = Path(tmp)
        app_dir = root / "Finzytrack"
        with socket.socket() as sock:
            sock.bind(("127.0.0.1", 0))
            port = sock.getsockname()[1]
        payload = {"currency": "EUR", "ledger_mode": mode}
        if mode == "existing":
            existing_ledger = root / "existing.beancount"
            existing_ledger.write_text(
                'option "operating_currency" "EUR"\n'
                "2026-01-01 open Assets:Cash EUR\n"
            )
            original_ledger_bytes = existing_ledger.read_bytes()
            payload["existing_ledger_path"] = str(existing_ledger)

        with (root / "server.log").open("w+") as log:
            process = subprocess.Popen(
                [str(package / "bin/finzytrack"), "--headless", "--port", str(port)],
                env={**os.environ, "XDG_DATA_HOME": tmp, "TMPDIR": tmp},
                stdout=log,
                stderr=subprocess.STDOUT,
                start_new_session=True,
            )
            try:
                url = f"http://127.0.0.1:{port}/api"
                deadline = time.monotonic() + 60
                while True:
                    try:
                        # The desktop launcher probes /health before it enters
                        # headless mode. Wait for that probe to finish so it
                        # cannot race setup's first SQLite export.
                        if "[launcher] Running headless." not in (
                            root / "server.log"
                        ).read_text():
                            raise OSError("Launcher is not ready")
                        with urllib.request.urlopen(
                            url + "/startup/tasks", timeout=1
                        ) as response:
                            assert response.status == 200
                        break
                    except (OSError, urllib.error.URLError):
                        if process.poll() is not None or time.monotonic() >= deadline:
                            raise RuntimeError("Backend did not start")
                        time.sleep(0.2)

                request = urllib.request.Request(
                    url + "/setup/complete",
                    data=json.dumps(payload).encode(),
                    headers={"Content-Type": "application/json"},
                )
                with urllib.request.urlopen(request, timeout=60) as response:
                    result = json.load(response)
                    assert response.status == 200, result
                config = app_dir / "config/config.yaml"
                assert "setup_complete: true" in config.read_text()
                assert "default_currency: EUR" in config.read_text()
                for directory in ("config", "data"):
                    for path in (app_dir / directory).rglob("*"):
                        assert path.stat().st_mode & 0o200, f"Read-only: {path}"
                if mode == "existing":
                    assert (
                        result["data"]["config"]["ledger_file"] == str(existing_ledger)
                    )
                    assert existing_ledger.read_bytes() == original_ledger_bytes
                    assert existing_ledger.stat().st_mode & 0o200
                    with existing_ledger.open("a"):
                        pass
                else:
                    ledgers = list((app_dir / "data").rglob("*.beancount"))
                    assert ledgers, "No ledgers found"
                    selected_ledger = Path(result["data"]["config"]["ledger_file"])
                    if not selected_ledger.is_absolute():
                        selected_ledger = app_dir / selected_ledger
                    assert selected_ledger.is_file(), f"Missing ledger: {selected_ledger}"
                    for ledger in [*ledgers, selected_ledger]:
                        assert "{default_currency}" not in ledger.read_text()
                        # Open a copied ledger for writing, just as edits and
                        # a repeated seed copy would do.
                        with ledger.open("a"):
                            pass
                print(f"{mode}: setup completed; config and ledgers are writable")
            except BaseException:
                log.seek(0)
                print(log.read(), file=sys.stderr)
                raise
            finally:
                try:
                    os.killpg(process.pid, signal.SIGTERM)
                except ProcessLookupError:
                    pass
                try:
                    process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.wait()
                assert not list(root.glob("finzytrack-seeds.*")), "Seed copy leaked"
