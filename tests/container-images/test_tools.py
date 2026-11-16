"""Offline tests for named-image dispatch and reusable OCI validation."""

import copy
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tarfile
import tempfile
import unittest

CLI, CHECKER = sys.argv[1:]
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("image_checks", CHECKER)
checks = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checks)

CONTRACT = {
    "user": "1000:1000",
    "entrypoint": ["/nix/store/example/bin/server"],
    "ports": ["8080/tcp"],
    "volumes": ["/data"],
    "forbiddenEnvironment": ["APP_SECRET"],
    "requiredMembers": ["etc/passwd"],
    "requireNixSymlinks": True,
}
CONFIG = {
    "User": CONTRACT["user"],
    "Entrypoint": CONTRACT["entrypoint"],
    "ExposedPorts": {"8080/tcp": {}},
    "Volumes": {"/data": {}},
    "Env": ["HOME=/data"],
}


class DispatchTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.registry = self.root / "registry.json"
        self.registry.write_text(json.dumps({
            name: {
                "package": f"{name}-image",
                "check": f"checks.x86_64-linux.image-{name}",
                "contract": f"legacyPackages.x86_64-linux.proxmoxImageContracts.{name}",
            }
            for name in ["9router", "radarr"]
        }))
        nix = self.root / "nix"
        nix.write_text(
            f"#!{sys.executable}\n"
            "import json, os, pathlib, sys\n"
            "pathlib.Path(os.environ['ARGV_FILE']).write_text(json.dumps(sys.argv[1:]))\n"
            "print(os.environ.get('NIX_STDOUT', ''))\n"
            "sys.exit(int(os.environ.get('NIX_EXIT', '0')))\n"
        )
        nix.chmod(0o755)
        self.argv = self.root / "argv.json"
        self.env = os.environ | {
            "PATH": str(self.root),
            "ARGV_FILE": str(self.argv),
        }

    def run_cli(self, action, *args, exit_code=0):
        return subprocess.run(
            [sys.executable, CLI, action, str(self.registry), CHECKER, *args],
            env=self.env | {"NIX_EXIT": str(exit_code)},
            capture_output=True,
            text=True,
            check=False,
        )

    def test_build(self):
        self.assertEqual(self.run_cli("build", "9router").returncode, 0)
        self.assertEqual(json.loads(self.argv.read_text()),
                         ["build", "--no-link", ".#9router-image"])

    def test_check_other_image_and_flake(self):
        result = self.run_cli("check", "--flake", "/a checkout", "radarr", "--show-trace")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(json.loads(self.argv.read_text()), [
            "build", "--no-link",
            "/a checkout#checks.x86_64-linux.image-radarr", "--show-trace",
        ])

    def test_copy_arguments_are_not_shell_expanded(self):
        destination = "oci-archive:/a path/$(touch should-not-exist).tar:radarr"
        self.assertEqual(self.run_cli("copy", "radarr", "--", "--tmpdir", "/tmp/a b",
                                     destination).returncode, 0)
        self.assertEqual(json.loads(self.argv.read_text()), [
            "run", ".#radarr-image.copyTo", "--", "--tmpdir", "/tmp/a b", destination,
        ])

    def test_exported_archive_uses_registered_contract(self):
        archive = self.root / "export.tar"
        ValidationTests().archive(archive)
        self.env["NIX_STDOUT"] = json.dumps(CONTRACT)
        result = self.run_cli("check", "--archive", str(archive), "radarr")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(self.argv.read_text()), [
            "eval", "--json", ".#legacyPackages.x86_64-linux.proxmoxImageContracts.radarr",
        ])

    def test_reject_unknown_image_and_missing_destination(self):
        self.assertNotEqual(self.run_cli("build", "unknown").returncode, 0)
        self.assertNotEqual(self.run_cli("copy", "9router").returncode, 0)
        self.assertFalse(self.argv.exists())

    def test_help_and_exit_status(self):
        self.assertEqual(self.run_cli("build", "--help").returncode, 0)
        self.assertFalse(self.argv.exists())
        self.assertEqual(self.run_cli("build", "radarr", exit_code=37).returncode, 37)


class ValidationTests(unittest.TestCase):
    def test_metadata(self):
        checks.check_config(CONFIG, CONTRACT)
        for key, value in [
            ("User", "0:0"), ("Entrypoint", ["/wrong"]), ("ExposedPorts", {}),
            ("Volumes", {}), ("Env", ["APP_SECRET=not-a-real-secret"]),
        ]:
            with self.subTest(key=key), self.assertRaises(AssertionError):
                checks.check_config(CONFIG | {key: value}, CONTRACT)

    def archive(self, path, bad_member=None, hardlink=None):
        layer = io.BytesIO()
        with tarfile.open(fileobj=layer, mode="w") as tar:
            entry = tarfile.TarInfo(bad_member or "etc/passwd")
            tar.addfile(entry, io.BytesIO())
            link = tarfile.TarInfo("bin/server")
            link.type = tarfile.SYMTYPE
            link.linkname = "/nix/store/example/bin/server"
            tar.addfile(link)
            if hardlink:
                link = tarfile.TarInfo("hardlink")
                link.type = tarfile.LNKTYPE
                link.linkname = hardlink
                tar.addfile(link)
        with tarfile.open(path, mode="w") as outer:
            def add(name, value):
                value = value if isinstance(value, bytes) else json.dumps(value).encode()
                info = tarfile.TarInfo(name)
                info.size = len(value)
                outer.addfile(info, io.BytesIO(value))

            def blob(value):
                value = value if isinstance(value, bytes) else json.dumps(value).encode()
                digest = hashlib.sha256(value).hexdigest()
                add(f"blobs/sha256/{digest}", value)
                return {"digest": f"sha256:{digest}"}

            manifest = {
                "config": blob({"config": copy.deepcopy(CONFIG)}),
                "layers": [blob(layer.getvalue())],
            }
            add("index.json", {"manifests": [blob(manifest)]})
            add("oci-layout", {"imageLayoutVersion": "1.0.0"})

    def test_archive_and_unsafe_paths(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "image.tar"
            self.archive(path)
            checks.check_archive(path, CONTRACT)
            for bad in ["/etc/passwd", "../passwd", "etc/../../passwd"]:
                self.archive(path, bad_member=bad)
                with self.subTest(member=bad), self.assertRaises(ValueError):
                    checks.check_archive(path, CONTRACT)
            for bad in ["/etc/passwd", "../passwd"]:
                self.archive(path, hardlink=bad)
                with self.subTest(hardlink=bad), self.assertRaises(ValueError):
                    checks.check_archive(path, CONTRACT)


if __name__ == "__main__":
    unittest.main(argv=[sys.argv[0]])
