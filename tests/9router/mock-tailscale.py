"""Offline Tailscale CLI fixture with deliberately non-atomic preference updates."""

import json
import os
from pathlib import Path
import sys
import time

root = Path("/run/mock-tailscale")
args = sys.argv[1:]
if args[0] == "set":
    sys.exit(0)
assert args[0] == "serve", args
assert (root / "alive").exists(), "Serve cleanup must finish before tailscaled stops"

# Detect overlap even if Restart=on-failure later repairs the final state.
# With the gateway lock removed, concurrent starts/stops must fail this test.
busy = root / "busy"
try:
    busy.mkdir()
except FileExistsError:
    (root / "overlap").touch()
    raise AssertionError("Concurrent Serve mutation")
try:
    state_file = root / "state.json"
    state = json.loads(state_file.read_text()) if state_file.exists() else {
        "advertised": [],
        "services": {},
        "node": False,
    }
    # Widen the real client's GetPrefs -> EditPrefs read-modify-write window.
    time.sleep(0.2)
    service = next((a.removeprefix("--service=") for a in args if a.startswith("--service=")), None)
    if args[1] in ("drain", "clear"):
        service = args[2]
        state["advertised"] = [s for s in state["advertised"] if s != service]
        if args[1] == "clear":
            state["services"].pop(service, None)
    elif service:
        state["advertised"] = sorted(set(state["advertised"]) | {service})
        state["services"][service] = args[-1]
    else:
        state["node"] = args[-1] != "off"
    temporary = root / f"state-{os.getpid()}.json"
    temporary.write_text(json.dumps(state))
    temporary.replace(state_file)
finally:
    busy.rmdir()
