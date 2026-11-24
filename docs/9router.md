# 9Router

9Router runs as an unprivileged Proxmox application container, with Nimi
supervising the application and SecretSpec retrieving its runtime secrets.
A separate tagged Tailscale gateway exposes `svc:9router-web` over HTTPS.

The image contains neither Tailscale nor a full NixOS system. The existing
NixOS service module remains available for other deployments.

## Build and export

Run locally on x86_64 Linux:

```sh
rtk nix run .#build-image -- 9router
rtk nix run .#check-image -- 9router
rtk nix run .#copy-image -- 9router \
  "oci-archive:$HOME/9router.oci.tar:9router"
rtk nix run .#check-image -- --archive "$HOME/9router.oci.tar" 9router
rtk proxy sha256sum "$HOME/9router.oci.tar"
```

The [container image interface](container-images.md) describes the shared
commands. `check-image` includes metadata, OCI archive, gateway, and VM smoke
checks. The image is a nix2container descriptor and its layers; export it as
an uncompressed OCI archive before importing it into Proxmox VE. Replacing a
cached archive does not update an existing container.

## Runtime contract

- The image starts Nimi and the secret resolver as **container root**, then
  drops to UID/GID 1000 with no supplementary groups or capabilities and with
  `no_new_privs` before executing 9Router. Keep the LXC **unprivileged**.
- Mount a backed-up, writable persistent volume at `/var/lib/9router`, owned by
  application UID/GID 1000. Under the standard unprivileged Proxmox mapping,
  those IDs are 101000 on the host; custom ID maps require different ownership.
- Mount a root-only service-account token read-only at
  `/run/secrets/onepassword-token`. Under that same standard map, container
  root is host UID/GID 100000.
- The backend listens on `0.0.0.0:20128`; limit access to the gateway with a
  firewall. Tailscale policy does not protect a directly reachable LAN port.
- All four secrets and a writable data directory are required. 9Router starts
  with `REQUIRE_API_KEY=true`. Nimi retries failures; secrets are retrieved
  again on restart, not hot-reloaded.

## 1Password setup

The default SecretSpec manifest references the `9router` item in the
`Infrastructure` vault. Configure these fields with the **existing deployment
values** when migrating; do not generate replacement signing or identity
secrets for an existing installation:

| Environment variable | 1Password item field |
|---|---|
| `INITIAL_PASSWORD` | `initial-password` |
| `JWT_SECRET` | `jwt-secret` |
| `API_KEY_SECRET` | `api-key-secret` |
| `MACHINE_ID_SALT` | `machine-id-salt` |

Use a service account with **read-only** access to the vault. Service-account
permissions are vault-scoped, not item-scoped: this token can read other items
in `Infrastructure`. A dedicated vault is preferable if that access is too
broad; changing the vault name requires rebuilding the image.

SecretSpec reads the bootstrap token via its file provider and does not pass
the token to Node. The application still receives its own four secrets.
Retrieval failures prevent it from starting, and a 1Password outage can prevent
a restart. Allow DNS and outbound HTTPS to 1Password.

## Create a guest with native Proxmox OCI import

These are operator-run examples for Proxmox VE 9.2. Replace the example
account, host, CT ID, storage pool, and bridge with values for your system.
OCI application containers are a
[technology preview](https://pve.proxmox.com/pve-docs/chapter-pct.html).
Do not overwrite an existing CT.

### 1. Transfer and verify the archive

Run locally, replacing the example SSH destination:

```sh
scp "$HOME/9router.oci.tar" operator@proxmox.example.com:9router.oci.tar
ssh operator@proxmox.example.com
```

The remaining commands run on the Proxmox host in Bash, with normal `sudo`
prompts. Check each step before continuing:

```bash
pveversion
sudo pct list
sudo pvesh get /cluster/nextid --output-format json
sudo pvesm status
sudo pvesm status --content vztmpl
sha256sum "$HOME/9router.oci.tar"
```

Compare the checksum with the local result. Install the archive at the path
reported by Proxmox; if it already exists, compare checksums instead of
overwriting it blindly:

```bash
TEMPLATE="$(sudo pvesm path local:vztmpl/9router.oci.tar)"
sudo install -d -m 0755 "$(dirname "$TEMPLATE")"
if sudo test -e "$TEMPLATE"; then
  sudo sha256sum "$TEMPLATE"
else
  sudo install -m 0644 "$HOME/9router.oci.tar" "$TEMPLATE"
  sudo sha256sum "$TEMPLATE"
fi
```

### 2. Create the stopped guest

Choose an unused ID and appropriate storage and bridge. `203`, `local-zfs`,
and `vmbr0` below are examples:

```bash
CTID=203
sudo pct create "$CTID" local:vztmpl/9router.oci.tar \
  --hostname 9router \
  --arch amd64 \
  --ostype unmanaged \
  --unprivileged 1 \
  --cores 2 \
  --memory 2048 \
  --swap 512 \
  --rootfs local-zfs:16 \
  --net1 name=net1,bridge=vmbr0,firewall=1,host-managed=1,ip=dhcp,ip6=dhcp,type=veth \
  --onboot 0 \
  --protection 1 \
  --start 0
sudo pct config "$CTID"
```

`host-managed=1` matters: the image has no DHCP client or network manager.
Reserve a stable address for the guest. Check that OCI import selected console
mode, the `/nix/store/.../bin/9router-nimi` entrypoint, and container root
UID/GID 0. Do not replace the entrypoint with `/sbin/init`, make the CT
privileged, or disable AppArmor.

### 3. Prepare persistent state

Allocate a separate data volume on the chosen storage:

```bash
sudo pct set "$CTID" --mp0 local-zfs:4,mp=/var/lib/9router,backup=1
sudo pct mount "$CTID"
```

Use the rootfs path printed by Proxmox. With the standard ID map and the
expected path, prepare the new volume's top-level directory:

```bash
ROOTFS="/var/lib/lxc/$CTID/rootfs"
if sudo mountpoint "$ROOTFS/var/lib/9router"; then
  sudo chown 101000:101000 "$ROOTFS/var/lib/9router" &&
    sudo chmod 0700 "$ROOTFS/var/lib/9router"
else
  echo "Data volume is not mounted; stop and investigate."
fi
sudo pct unmount "$CTID"
```

Stop if the mountpoint check fails. Never change ownership of an unrelated
existing volume. For a migration, copy a consistent state backup while the old
writer is stopped, and verify the copied ownership.

### 4. Provision the 1Password bootstrap token

Create a new root-only directory dedicated to this guest. Do not overwrite an
existing directory or its token. These IDs assume the standard mapping:

```bash
SECRETS="/var/lib/9router-secrets/$CTID"
if sudo test -e "$SECRETS"; then
  echo "Directory exists; inspect it before continuing."
else
  sudo install -d -m 0700 -o 100000 -g 100000 "$SECRETS"
fi
```

After confirming the directory is the intended new one, authenticate sudo and
enter the raw service-account token at the hidden prompt. The token must be a
single value without a trailing newline; never paste it into chat, repository
files, or command arguments.

```bash
sudo -v
read -r -s -p '1Password service-account token: ' OP_TOKEN
printf '\n'
if [ -n "$OP_TOKEN" ]; then
  printf '%s' "$OP_TOKEN" | sudo sh -c '
    set -eu
    umask 077
    tmp="$(mktemp "$1/.onepassword-token.XXXXXXXX")"
    trap '\''rm -f "$tmp"'\'' EXIT
    cat > "$tmp"
    chown 100000:100000 "$tmp"
    chmod 0400 "$tmp"
    ln -- "$tmp" "$1/onepassword-token"
    rm -f -- "$tmp"
    trap - EXIT
  ' sh "$SECRETS"
else
  echo "No token entered; do not start the guest."
fi
unset OP_TOKEN

sudo stat -c '%u:%g %a %n' "$SECRETS" "$SECRETS/onepassword-token"
sudo namei -l "$SECRETS/onepassword-token"
```

Verify directory ownership/mode `100000:100000 700`, file ownership/mode
`100000:100000 400`, and traversal through parent directories by mapped root.
Only after verifying those values, attach the directory:

```bash
sudo pct set "$CTID" --mp1 "$SECRETS,mp=/run/secrets,ro=1"
```

Bind-mounted secrets are **not included** in vzdump backups: arrange a
protected backup or reprovisioning procedure.

### 5. Restrict network access and start

`firewall=1` on the NIC is not a complete firewall policy. Configure and
verify an active PVE firewall with inbound default DROP, allowing TCP 20128
only from the gateway's actual private address. Review IPv6, DHCP, and return
traffic. Keep the guest stopped until the policy is ready.

```bash
sudo pct config "$CTID"
sudo pct start "$CTID"
sudo pct status "$CTID"
sudo pct console "$CTID"
```

The console shows Nimi/application logs, not a login shell. Detach with
Ctrl+A, Q. From the gateway, check `/login` returns HTTP 200, an unauthenticated
API request is rejected, and an existing API key works. Verify the application
persists across restart. A non-gateway machine must not reach port 20128.

## Separate Tailscale gateway

Import `nixosModules.tailscale-service-gateway` on a tagged gateway and use a
stable, private backend address; the address here is documentation-only:

```nix
{
  services.tailscaleServiceGateway = {
    enable = true;
    services."9router-web".backend = "http://192.0.2.203:20128";
  };
}
```

Define `svc:9router-web` with endpoint `tcp:443`, enable HTTPS certificates,
approve the gateway advertisement, and grant intended clients access to that
Service. The module manages only configured Services and does not change
tailnet policy or open public port 443. Its shared lock serializes
repository-managed Serve changes; external Tailscale commands do not use it.
The gateway-to-backend hop is HTTP unless separately secured.

## Manual image updates

Record the deployed archive checksum and image digest. Changing a registry tag
or cached template does **not** update an existing LXC.

Before updating, stop the writer and verify a backup that includes `mp0`.
Back up or reprovision the secret directory separately. A reviewed replacement
guest with its own data volume is the conservative option: copy consistent
state, configure secrets and firewall, verify login, API-key rejection,
authenticated access, and restart, then switch the gateway.

Do not attach one writable database volume to two running guests. For rollback,
account for writes and database migrations: switching to an old image alone
does not restore an earlier database. Keep the old guest and verified backup
until the replacement is accepted.

## Revisit declarative Tailscale Serve

The pinned `services.tailscale.serve` module writes a version `0.0.1`
configuration and runs `tailscale serve set-config --all`; its current format
does not express the desired HTTPS-to-HTTP behavior. The CLI's `--https=443`
flag is used instead.

Track [Tailscale PR #20116](https://github.com/tailscale/tailscale/pull/20116),
[PR #19554](https://github.com/tailscale/tailscale/pull/19554),
[Tailscale issue #18381](https://github.com/tailscale/tailscale/issues/18381),
and [nixpkgs issue #530174](https://github.com/NixOS/nixpkgs/issues/530174).
Before replacing the units, verify released support in the pinned versions and
account for every Service affected by `--all`.
