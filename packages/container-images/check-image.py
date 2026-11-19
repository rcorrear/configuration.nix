"""Validate image metadata and OCI layer paths without extracting the image."""

import json
from pathlib import PurePosixPath
import sys
import tarfile


def check_config(config, contract):
    assert config["User"] == contract["user"], "Unexpected image startup user"
    assert config["Entrypoint"] == contract["entrypoint"], "Unexpected entrypoint"
    for port in contract["ports"]:
        assert port in config.get("ExposedPorts", {}), f"Missing port: {port}"
    for volume in contract["volumes"]:
        assert volume in config.get("Volumes", {}), f"Missing volume: {volume}"
    names = {entry.split("=", 1)[0] for entry in config.get("Env", [])}
    assert not names.intersection(contract["forbiddenEnvironment"]), (
        "Runtime secrets must not be baked into the image environment"
    )


def check_member(name):
    if name.startswith("/") or ".." in PurePosixPath(name).parts:
        raise ValueError(f"unsafe layer member name: {name!r}")


def check_archive(path, contract):
    with tarfile.open(path) as archive:
        layout = json.load(archive.extractfile("oci-layout"))
        assert layout["imageLayoutVersion"] == "1.0.0"
        index = json.load(archive.extractfile("index.json"))
        assert len(index["manifests"]) == 1

        def blob(digest):
            algorithm, value = digest.split(":", 1)
            assert algorithm == "sha256"
            return archive.extractfile(f"blobs/{algorithm}/{value}")

        manifest = json.load(blob(index["manifests"][0]["digest"]))
        config = json.load(blob(manifest["config"]["digest"]))
        check_config(config["config"], contract)
        members = set()
        absolute_symlinks = 0
        for layer in manifest["layers"]:
            with tarfile.open(fileobj=blob(layer["digest"]), mode="r|*") as tar:
                for entry in tar:
                    check_member(entry.name)
                    # Hardlinks name archive members; absolute symlink targets
                    # such as /nix/store/... are valid container paths.
                    if entry.islnk():
                        check_member(entry.linkname)
                    if entry.issym() and entry.linkname.startswith("/nix/store/"):
                        absolute_symlinks += 1
                    members.add(entry.name.removeprefix("./"))
        for member in contract["requiredMembers"]:
            assert member in members, f"Missing layer member: {member}"
        if contract["requireNixSymlinks"]:
            assert absolute_symlinks > 0, "Nix store symlink targets must remain intact"
        print(f"Validated {len(members)} relative layer paths and preserved Nix symlinks")


if __name__ == "__main__":
    mode, image, contract_file = sys.argv[1:]
    with open(contract_file) as stream:
        contract = json.load(stream)
    if mode == "archive":
        check_archive(image, contract)
    elif mode == "descriptor":
        with open(image) as stream:
            check_config(json.load(stream)["image-config"], contract)
    else:
        raise ValueError(f"Unknown validation mode: {mode}")
