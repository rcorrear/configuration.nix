# ProxMenux on Proxmox

ProxMenux is optional: the [9Router setup](9router.md) uses native Proxmox OCI
import without it. This guide covers a separately chosen management layer.

The user runs privileged host commands in their own SSH terminal. No sudo
policy change is required, and no installer is executed by this repository.

## Channel decision

Stable ProxMenux [v1.2.7](https://github.com/MacRimi/ProxMenux/releases/tag/v1.2.7)
introduced **OCI manager Apps** (Technology Preview), so v1.2.7 or later on
the stable channel is a valid option. Beta remains an alternative only after
explicit acceptance of the beta channel; it is not required for OCI support.

The documented beta entrypoint is
[`install_proxmenux_beta.sh`](https://github.com/MacRimi/ProxMenux/blob/develop/install_proxmenux_beta.sh).
Do not silently install beta in place of stable. The stable installer is
[`install_proxmenux.sh`](https://github.com/MacRimi/ProxMenux/blob/main/install_proxmenux.sh).

## Operator-run installation

For the stable channel, use an interactive SSH session on your Proxmox host.
Download the installer as the normal user before running anything as root:

```sh
curl --fail --location --proto '=https' --tlsv1.2 \
  https://raw.githubusercontent.com/MacRimi/ProxMenux/main/install_proxmenux.sh \
  --output install_proxmenux.sh
less install_proxmenux.sh
sudo bash ./install_proxmenux.sh
```

This follows the upstream installation channel, not a fully pinned/offline
installation: the installer downloads additional upstream components. Reviewing
the bootstrap does not audit those components. Read and accept the installer's
confirmation prompts; do not use an unattended curl-to-root-shell pipeline.

ProxMenux installs host packages and management files and can install a
root-running Monitor service with a dashboard on TCP port 8008. Keep it reachable
only from the trusted management network, configure authentication, and do not
expose it publicly. Review the selected installer's current behavior before
accepting. Avoid unrelated optimization, update-all, and host-change options.

After installation:

```sh
sudo menu
sudo systemctl status proxmenux-monitor.service
```

Confirm **OCI manager Apps** is present and record the installed version/channel
before creating or updating any guest. Existing guests must remain unchanged.

## Deployment gates

Before deploying 9Router:

1. Verify the built OCI archive and its entrypoint/user metadata.
2. Choose the application network, stable address, and tagged gateway host.
3. Select a registry and authorize publishing, or import a local OCI archive.
4. Configure persistent data and runtime secret mounts.
5. Restrict the private backend to the gateway and approve the named Service.
6. Test startup, restart, backup/restore, and image replacement before cutover.

The [OCI manager documentation](https://github.com/MacRimi/ProxMenux/blob/develop/oci/README.md)
describes one LXC per image and explicit update/recreation workflows. Native
Proxmox OCI import alone does not provide that orchestration.
