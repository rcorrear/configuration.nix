"""Dispatch named-image commands to the current flake, without shell expansion."""

import argparse
import importlib.util
import json
import subprocess
import sys


sys.dont_write_bytecode = True


def main():
    action, registry_file, checker = sys.argv[1:4]
    with open(registry_file) as stream:
        registry = json.load(stream)
    parser = argparse.ArgumentParser(prog=f"{action}-image")
    parser.add_argument("--flake", default=".", help="Flake checkout or reference (default: .)")
    if action == "check":
        parser.add_argument("--archive", help="Validate an exported OCI archive instead of building checks")
    parser.add_argument("image", choices=sorted(registry))
    parser.add_argument("arguments", nargs=argparse.REMAINDER)
    args = parser.parse_args(sys.argv[4:])
    target = registry[args.image]
    extra = args.arguments
    if extra[:1] == ["--"]:
        extra = extra[1:]
    if action == "build":
        command = ["nix", "build", "--no-link", f"{args.flake}#{target['package']}"]
    elif action == "check":
        if args.archive:
            if extra:
                parser.error("extra Nix build arguments do not apply to --archive")
            result = subprocess.run(
                ["nix", "eval", "--json", f"{args.flake}#{target['contract']}"],
                capture_output=True, text=True, check=False,
            )
            if result.returncode:
                sys.stderr.write(result.stderr)
                return result.returncode
            spec = importlib.util.spec_from_file_location("image_checks", checker)
            checks = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(checks)
            checks.check_archive(args.archive, json.loads(result.stdout))
            return 0
        command = ["nix", "build", "--no-link", f"{args.flake}#{target['check']}"]
    elif action == "copy":
        if not extra:
            parser.error("a copy destination is required, for example oci-archive:/path/image.tar:name")
        command = ["nix", "run", f"{args.flake}#{target['package']}.copyTo", "--"]
    else:
        parser.error(f"unknown action: {action}")
    return subprocess.run(command + extra, check=False).returncode


if __name__ == "__main__":
    sys.exit(main())
