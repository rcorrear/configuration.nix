"""Validate the exported OCI layers without extracting or executing the image."""

import json
from pathlib import PurePosixPath
import sys
import tarfile


def check_member(name):
    if name.startswith("/") or ".." in PurePosixPath(name).parts:
        raise ValueError(f"unsafe layer member name: {name!r}")


def check_archive(path, expected_user="1000:1000"):
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
        assert config["config"]["User"] == expected_user
        members = set()
        absolute_symlinks = 0
        for layer in manifest["layers"]:
            with tarfile.open(fileobj=blob(layer["digest"]), mode="r|*") as tar:
                for entry in tar:
                    check_member(entry.name)
                    # Hardlink targets are archive member names; symlink targets
                    # are container filesystem paths and can be absolute.
                    if entry.islnk():
                        check_member(entry.linkname)
                    if entry.issym() and entry.linkname.startswith("/nix/store/"):
                        absolute_symlinks += 1
                    members.add(entry.name.removeprefix("./"))
        assert "etc/group" in members
        assert "etc/passwd" in members
        assert absolute_symlinks > 0, "Nix store symlink targets must remain intact"
        print(f"Validated {len(members)} relative layer paths and preserved Nix symlinks")


if __name__ == "__main__":
    check_archive(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else "1000:1000")
