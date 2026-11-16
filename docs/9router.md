# 9Router

9Router is packaged as an application image, with Nimi supervising
a Nix modular service. A separate, tagged Tailscale gateway exposes
`svc:9router-web` over HTTPS. The application image has no Tailscale identity,
NixOS, systemd, SSH daemon, or Home Manager environment.

The former `nixosConfigurations."9router"` full-system guest is superseded.
The existing NixOS service module/aspect remains available for legacy consumers;
OK1EBF does not include it. No existing data is deleted.

This guide uses **native Proxmox VE OCI import**, not ProxMenux or Docker.
Proxmox converts the application image into an unprivileged LXC and imports its
entrypoint, environment, working directory, and user. OCI application containers
are still described as a technology preview in the
[Proxmox container documentation](https://pve.proxmox.com/pve-docs/chapter-pct.html).
The commands below target PVE 9.2; check `pct help create` on older installations.

## Build and local validation

```sh
rtk nix run .#build-image -- 9router
rtk nix run .#check-image -- 9router
```

The shared [container image interface](container-images.md) selects the current
system automatically. `check-image` builds the aggregate flake check, including
HTTP smoke, gateway, metadata, and OCI archive checks; `nix flake check` runs
these too. Building the image already builds its Nimi runner.

`9router-image` is a nix2container image descriptor plus its layer references,
not an LXC rootfs tarball. Run the following **locally**, in the checkout
containing this configuration. These commands work in fish as well as Bash and write
the archive to your home directory; no placeholder directory needs replacing:

```sh
rtk nix run .#copy-image -- 9router \
  "oci-archive:$HOME/9router.oci.tar:9router"
rtk ls -lh "$HOME/9router.oci.tar"
rtk proxy tar -tf "$HOME/9router.oci.tar" oci-layout index.json
rtk proxy sha256sum "$HOME/9router.oci.tar"
rtk nix run .#check-image -- --archive "$HOME/9router.oci.tar" 9router
```

The archive check reads every image layer without extracting it. It rejects
absolute member names and parent-directory traversal, while preserving absolute
symlink targets such as `/nix/store/...`, which are valid inside the container.
Run it after exporting, not just against the outer OCI layout.

Keep the uncompressed `.tar` extension: Proxmox detects the OCI layout inside
the archive. Do not extract it into a rootfs yourself or pass it to `pct restore`,
which is for container backups. Use `pct create` as shown below.

A registry is optional for this local-archive workflow.
Publishing requires a separately selected registry and explicit authorization.
Use `copy-image` with an explicitly selected `docker://` destination.
Authenticate using an external credential store;
never put registry credentials into Nix files or command arguments.

The image uses Nimi's pinned runner and nix2container directly: the pinned
Nimi `settings.container.perms` submodule is malformed. Direct composition lets
us set `/tmp` to mode `1777` without patching the upstream runtime.
The pinned nix2container tar writer is locally patched to emit relative layer
member names. Its image builder and exporter use the same patched source so
the layer digests agree.

## Application deployment contract

- `amd64`, OCI entrypoint supplied by the image. Application user/group
  `1000:1000`; the optional SecretSpec variant starts its resolver as container
  root and drops privileges before executing application code.
- Private HTTP listener on `0.0.0.0:20128`. Do not expose this port to the LAN,
  public internet, or arbitrary tailnet clients.
- Mount a backed-up, persistent volume at `/var/lib/9router`, writable by the
  image's UID/GID. For an unprivileged LXC, map ownership through its actual
  Proxmox ID map; do not assume host UID 1000 is correct.
- Mount a trusted shell environment file read-only at `/run/secrets/9router.env`,
  readable only by the application and the administrators provisioning it.
  Supply `INITIAL_PASSWORD`, `JWT_SECRET`, `API_KEY_SECRET`, and `MACHINE_ID_SALT`
  from the existing deployment. Use shell-safe quoting. An existing 1Password
  item is not assumed; creating one is described below.
  This image does not run the NixOS secretspec unit or read `/etc/opnix-token`.
  Generate/provision the runtime file outside the image and repository.
  Alternatively, use the explicit `9router-secretspec-image` variant below;
  it resolves these values from 1Password at process startup.
- The runner refuses to start without those values or a writable data directory.
  It always sets `REQUIRE_API_KEY=true`. Existing persisted application settings
  must also be audited during migration.
- No SSH user or guest sudo password is needed. Manage the process through PVE.

## Create the guest with plain Proxmox

### 1. Transfer and verify the archive

Run **locally**:

```sh
scp "$HOME/9router.oci.tar" rcorrear@pve01.home.arpa:9router.oci.tar
ssh rcorrear@pve01.home.arpa
```

The remaining host commands run **on pve01 in Bash**, not in the local fish
session. They use normal `sudo` prompts; passwordless sudo is not required.
Do not execute them as an unattended script. Check each step before continuing.

```bash
pveversion
sudo pct list
sudo pvesh get /cluster/nextid --output-format json
sudo pvesm status
sudo pvesm status --content vztmpl
sha256sum "$HOME/9router.oci.tar"
```

Compare the checksum with the local result. `local` must accept container
templates and `zpool1` must have free space. ID **107 was available when
planned**, but must be rechecked: cluster IDs can change. If it is occupied,
choose another unused ID and use it consistently below. Do not overwrite or
destroy an existing guest.

Install the archive into the template location resolved by Proxmox, rather
than assuming the storage's filesystem path:

```bash
TEMPLATE="$(sudo pvesm path local:vztmpl/9router.oci.tar)"
sudo install -d -m 0755 "$(dirname "$TEMPLATE")"
sudo install -m 0644 "$HOME/9router.oci.tar" "$TEMPLATE"
sudo sha256sum "$TEMPLATE"
```

### 2. Create the application container, initially stopped

Set the reviewed, unused ID and allocate the guest:

```bash
CTID=107
sudo pct create "$CTID" local:vztmpl/9router.oci.tar \
  --hostname 9router \
  --arch amd64 \
  --ostype unmanaged \
  --unprivileged 1 \
  --cores 2 \
  --memory 2048 \
  --swap 512 \
  --rootfs zpool1:16 \
  --net1 name=net1,bridge=vmbr1,firewall=1,host-managed=1,ip=dhcp,ip6=auto,type=veth \
  --onboot 0 \
  --protection 1 \
  --start 0
sudo pct config "$CTID"
```

This follows Renovate's bridge and resource settings but generates a fresh MAC.
**`host-managed=1` is important:** the application image has no DHCP client or
network service. PVE configures the interface, including obtaining the DHCP lease.
Reserve a stable address for the new MAC before configuring the gateway.

The creation log should detect an OCI archive. Check that the resulting config
has the Nimi entrypoint (a `/nix/store/.../bin/9router-nimi` path), console mode,
and `lxc.init.uid: 1000` / `lxc.init.gid: 1000`. Do not replace the entrypoint
with `/sbin/init` or start systemd. If these are missing, stop and check the
PVE version and archive format instead of working around failed OCI import.

The application guest needs neither Tailscale's `/dev/net/tun` passthrough nor
Renovate's nesting feature. Do not make it privileged or disable AppArmor.
Tailscale remains on the separate gateway.

### 3. Allocate and prepare persistent state

The 16 GiB root disk is replaceable application storage, **not** the database
volume. Allocate a separate backed-up data disk; the example starts with
4 GiB on the same pool, adjustable before allocation:

```bash
sudo pct set "$CTID" --mp0 zpool1:4,mp=/var/lib/9router,backup=1
sudo pct config "$CTID"
```

For this newly created unprivileged guest with **no custom `lxc.idmap` entries**,
Proxmox's standard mapping maps container UID/GID 1000 to host UID/GID 101000.
The ownership commands below apply only to that mapping. If an administrator
has customized the map, calculate the actual mapped IDs before proceeding.

With the guest still stopped, mount its filesystems and prepare only the new
data volume's top-level directory:

```bash
sudo pct mount "$CTID"
```

Confirm the printed rootfs mount path is `/var/lib/lxc/107/rootfs` for ID 107.
If it differs, use that actual path. In the same Bash session:

```bash
ROOTFS="/var/lib/lxc/$CTID/rootfs"
sudo mountpoint "$ROOTFS/var/lib/9router"
sudo chown 101000:101000 "$ROOTFS/var/lib/9router"
sudo chmod 0700 "$ROOTFS/var/lib/9router"
sudo pct unmount "$CTID"
```

Do not proceed if the `mountpoint` check fails: changing an image directory is
not a substitute for mounting persistent storage. If migrating existing state,
copy it while both writers are stopped, then review ownership of the copied
files too. Do not recursively change ownership of an unrelated existing volume.
Always unmount before using other `pct` operations.

### 4. Provision secrets outside the image

Create a host directory dedicated to this guest and bind it read-only:

```bash
SECRETS="/var/lib/9router-secrets/$CTID"
sudo install -d -m 0700 -o 101000 -g 101000 "$SECRETS"
sudoedit "$SECRETS/9router.env"
```

In the editor, supply the four values from the deployment being migrated.
Use shell-safe quoting: this is a trusted shell environment file, not a JSON
document. Do not leave the following entries empty, use production credentials
in commands, or paste them into chat:

```sh
INITIAL_PASSWORD=''
JWT_SECRET=''
API_KEY_SECRET=''
MACHINE_ID_SALT=''
```

Then restrict the file and attach its directory:

```bash
sudo chown 101000:101000 "$SECRETS/9router.env"
sudo chmod 0400 "$SECRETS/9router.env"
sudo pct set "$CTID" --mp1 "$SECRETS,mp=/run/secrets,ro=1"
```

The mapped IDs assume the standard map verified above. The bind mount exposes
the file at `/run/secrets/9router.env`; it does not copy it into the image or
put the values into PVE's environment/command-line configuration.
**Bind-mounted secrets are not included in vzdump backups.** Back them up through
an appropriately protected/encrypted host backup or reprovision from 1Password.

### 5. Restrict network access before first start

`firewall=1` on the NIC alone is **not** a complete firewall policy. Before
starting the guest, use the PVE firewall UI to:

1. Verify that the cluster's existing firewall backend is active. Do not blindly
   enable or replace host-wide firewall policy over SSH.
2. Enable the new CT's firewall, with inbound default DROP and outbound ACCEPT.
3. Add an inbound TCP allow rule for destination port **20128**, source limited
   to the gateway's actual private address (a `/32` for IPv4).
4. Check inherited rules/security groups do not allow broader access. Review
   IPv6 as well; IPv4-only restrictions do not protect an IPv6 listener.
5. Preserve the required DHCP, IPv6 discovery, and established-return traffic
   handling, and test the rules before exposing production state.

Use the source address selected by the gateway's route to the backend, not an
assumed Tailscale virtual IP. If the gateway is not selected or firewall rules
are not ready, leave the application stopped. A private isolated backend network
is another option, but this example preserves the requested `vmbr1` attachment.

### 6. Start and verify

After the state volume, secrets, stable address, and firewall are ready:

```bash
sudo pct config "$CTID"
sudo pct start "$CTID"
sudo pct status "$CTID"
sudo pct console "$CTID"
```

The console shows Nimi/application output, not a login shell. Use its escape
sequence to detach (normally Ctrl+A, Q). Do not expect `pct enter`, `systemctl`,
`passwd`, or a shell under `/bin`: this is not a full distribution image.
For a failed start, inspect the PVE task log and retry with
`sudo pct start "$CTID" --debug` only after confirming it is stopped.

From the **gateway**, use `curl` against the reserved private address to check
`/login` (HTTP 200), `/dashboard` (redirects to login without a session), and
an unauthenticated POST to `/v1/chat/completions` (HTTP 401). An allowed client
must also be able to make an authenticated model request before cutover.
Test a non-gateway machine cannot reach port 20128 directly.

Then configure the named Service as below and test access through HTTPS.
Keep `onboot: 0` during initial validation; afterward, enable automatic start
only if desired with `sudo pct set "$CTID" --onboot 1`.

### Extraction fails at `unlink("/etc/group")`

An earlier archive contained absolute layer member names such as
`/etc/group`. The older Proxmox importer joined that name to the extraction
directory before removing existing paths; an absolute name discarded the
directory prefix. The resulting unprivileged attempt to unlink the host's
`/etc/group` failed with `EACCES`. This was an image-path compatibility problem,
not a reason to loosen host filesystem permissions.

**Do not retry the old archive as a privileged container, disable AppArmor,
or change `/etc/group` permissions.** The current image builder emits relative
names and the archive regression check catches the old output. Rebuild, re-export
`$HOME/9router.oci.tar`, rerun the archive check, and transfer/install the new
archive into PVE's template cache again, comparing checksums. Merely retrying
`pct create` with the old cached archive does not apply the fix.

Check whether the failed CT was cleaned up before retrying. If its config still
exists, inspect it rather than using `--force` or deleting volumes blindly.
Nesting does not fix this extraction-stage error.

Proxmox also has an
[upstream fix rejecting unsafe layer paths](https://github.com/proxmox/proxmox-rs/commit/d6a06a127a0b1efc320297d3b5533e4406b893ac).
Check package release notes for availability; an updated importer can reject
the old archive rather than making its absolute paths safe. The corrected
image is still required.

## Optional 1Password runtime with SecretSpec

The working `9router-image` remains file-based. **`9router-secretspec-image`**
instead runs the pinned SecretSpec CLI before launching Node; it never sources
`9router.env` or falls back to that file when 1Password fails. Both variants
use the same persistent state, application UID, and separate Tailscale gateway.
The process tree becomes Nimi → launcher → SecretSpec → Node. The `op` CLI runs
only while resolving credentials/secrets, not as a daemon.

The SecretSpec image's OCI user is **`0:0`**, not `1000:1000`: Nimi, the
launcher, SecretSpec, and its short-lived `op` subprocess run as container root.
Before application code runs, an immutable wrapper uses `setpriv` to set all
UID/GID identities to 1000, clear supplementary groups and all capability sets,
and enable `no_new_privs`. There is no setuid executable or sudo rule. Root's
working directory and configuration/cache directories are private temporary
directories, not the application-writable data volume.

**Keep the LXC unprivileged.** Under the verified default mapping, container
root maps to host UID/GID **100000**; the application still maps to **101000**.
Container root is not host root. A custom ID map requires recalculating both.

### Prepare 1Password

1. Create a dedicated vault named **`9Router Production`** and an item named
   **`9router`** in the account used for this deployment.
2. Add these custom fields, copying the **existing migrated values** from the
   currently working deployment, not generating replacements:

   | Environment variable | Item field |
   |---|---|
   | `INITIAL_PASSWORD` | `initial-password` |
   | `JWT_SECRET` | `jwt-secret` |
   | `API_KEY_SECRET` | `api-key-secret` |
   | `MACHINE_ID_SALT` | `machine-id-salt` |

   Changing signing/key/identity secrets can invalidate existing sessions, keys,
   or identity. The dashboard password may already be persisted in the database.
   These are application deployment secrets, not upstream provider API keys.
3. Create a **service account with read-only access to this dedicated vault**.
   Do not grant write, sharing, vault-creation, or access to the broader
   Infrastructure vault. Standard service-account access is vault-scoped, not
   item-scoped: any other item placed in this vault is also exposed to this token.

Vault and item names are non-secret build parameters in
`packages/9router/secretspec.nix`. No vault is created automatically.

### Provision the bootstrap credential

On **pve01, in Bash**, prepare a separate, root-only secret directory for the
**candidate guest**, using its reviewed CT ID. Keep the existing file-mode
directory unchanged for rollback. For the verified standard UID map:

```bash
CTID=107
SECRETS="/var/lib/9router-secrets/$CTID-secretspec"
sudo -v
sudo install -d -m 0700 -o 100000 -g 100000 "$SECRETS"
read -r -s -p '1Password service-account token: ' OP_TOKEN
printf '\n'
printf '%s' "$OP_TOKEN" | sudo sh -c \
  'umask 077; cat > "$1/onepassword-token"; chown 100000:100000 "$1/onepassword-token"; chmod 0400 "$1/onepassword-token"' \
  sh "$SECRETS"
unset OP_TOKEN
sudo pct set "$CTID" --mp1 "$SECRETS,mp=/run/secrets,ro=1"
```

`107` identifies the existing deployment; **substitute the unused candidate ID**
before running provisioning commands. Attach this mount while the candidate is
stopped. Do not reuse the legacy directory's ownership of 101000: that would
make the token readable by the application. The data volume remains owned by
101000; do not change it to container root.

The file must contain **only the token, without a trailing newline**. Do not
store it in the image, repository, PVE environment, command arguments, or chat.
As with `9router.env`, the bootstrap file needs a separate protected backup or
reprovisioning procedure; it is not part of a vzdump backup of the bind mount.
The application UID cannot read this directory/token, resolver memory, or its
private cache directories using ordinary process/file permissions. It still
receives its own four secrets and can leak those if compromised. This protects
the broader bootstrap credential, not against a container/kernel escape.
A dedicated read-only vault remains important defense in depth.

SecretSpec obtains the token through its native `file://` credential provider.
It passes the token internally to `op`, **not to Node's environment**. The
launcher clears an ambient `OP_SERVICE_ACCOUNT_TOKEN`, selects the pinned `op`
binary explicitly, and uses private temporary config/cache directories. Nix
includes the unfree 1Password CLI with a package-specific license allowance.

### Build, test, and deploy a candidate

```sh
rtk nix run .#build-image -- 9router-secretspec
rtk nix run .#check-image -- 9router-secretspec
rtk nix run .#copy-image -- 9router-secretspec \
  "oci-archive:$HOME/9router-secretspec.oci.tar:9router-secretspec"
rtk nix run .#check-image -- --archive "$HOME/9router-secretspec.oci.tar" 9router-secretspec
```

Use the reviewed **replacement-guest** procedure below, substituting this
archive for the file-based archive. Do not assume replacing a template updates
CT 107. Retain the old guest, backed-up state, and old environment file for
rollback; the new variant ignores that environment file. Never run both
guests against the same writable data volume.

Allow DNS, time synchronization, and outbound HTTPS to 1Password through the
deployment's network policy. The smoke check boots a NixOS
test VM (KVM recommended) rather than a single-UID Bubblewrap namespace, so it
can test real root-to-1000 privilege transitions without host sudo. Tests use
the real pinned SecretSpec with a fake `op` provider and dummy credentials.
They verify token access is denied to UID 1000, capabilities/groups are cleared,
privilege gain is disabled, HTTP startup works, and stop/restart works.
They do not verify your vault,
token permissions, or network. After provisioning a candidate, verify:

- Console shows startup without missing-secret/authentication errors; never
  dump the environment or secret file to diagnose it.
- `/login` returns 200 from the gateway and an existing API key still works.
- A guest restart resolves the same values and preserves application state.
- With an invalid token on a disposable candidate, the app does not start.

All four values are required. Retrieval/authentication failures prevent Node
from starting; Nimi retries startup after 10 seconds. Values are fetched at
each application start, **not hot-reloaded**. A vault outage can therefore
prevent a restart even if a running instance was healthy. Token/secret rotation
is an explicit operator action followed by a reviewed restart.

## Separate Tailscale gateway

The reusable NixOS module is exported as
`nixosModules.tailscale-service-gateway`. Attach it only to the selected tagged
gateway host, not to OK1EBF. Example configuration (replace the documentation IP
with a stable private application address):

```nix
{
  services.tailscaleServiceGateway = {
    enable = true;
    services."9router-web".backend = "http://192.0.2.107:20128";
  };
}
```

The module enables tailscaled and manages one scoped unit per Service. It does
not select a tag, authenticate the gateway, edit tailnet policy, open public
port 443, or reset unrelated Serve configurations. Stopping a unit drains and
clears only its Service, without waiting for existing requests to finish.

Define `svc:9router-web` with endpoint `tcp:443` in the tailnet, enable HTTPS
certificates, tag the gateway, and approve its advertisement. Grant clients
access to the Service itself, independently of other Services on that gateway:

```json
{
  "src": ["group:9router-users"],
  "dst": ["svc:9router-web"],
  "ip": ["tcp:443"]
}
```

This is a fragment to merge into the existing grants policy; define the group
and review existing broad grants, which remain additive. It does not configure
the policy automatically. The expected URL is
`https://9router-web.pig-duckbill.ts.net`.

Use a private backend network or PVE firewall rules permitting port 20128 only
from the gateway. Tailscale policy does not protect direct LAN access.
Remember that the current Tailscale host advertises LAN subnet routes: clients
with access to those routes must not be able to bypass the gateway either.
The gateway-to-backend hop is HTTP unless separately configured for TLS.

## Cutover and updates

Keep the original gateway running until the replacement passes local and PVE checks.
For final state migration, stop its writer and back up the complete
`/var/lib/9router` directory (possibly backed by `/var/lib/private/9router`
under DynamicUser). Copy it securely to the new data volume and adjust ownership
for the image user. Never copy databases or tokens into this repository.

Verify the login page, rejection of unauthenticated gateway requests, an
authorized model request, persistence across restart, and an image replacement.
From tailnet clients, test both allowed and denied Service access and blocked
direct backend access. Back up data before testing image upgrades; rolling back
an image alone does not undo database migrations.

### Manual image updates without ProxMenux

Record each deployed archive's checksum and the OCI manifest digest. Publish
versioned images if a registry is used; changing a tag or replacing the template
archive does **not** update an existing LXC. There is no `pct` equivalent of
`docker compose pull && docker compose up` in this guide.

Prefer a reviewed replacement guest rather than an in-place
destructive rootfs replacement:

1. Build/export the new image and verify its checksum after transfer.
2. While the current guest is stopped for a consistent backup, create a vzdump
   backup that includes `mp0` (`backup=1`). Store it on an available
   backup-capable storage and verify the backup task. Back up/reprovision the
   host secret directory separately.
3. Follow the creation steps with a **new, unused CT ID**, a distinct hostname,
   and a fresh data volume. Do not overwrite CT 107 or attach the same writable
   database volume to two running guests.
4. Copy a consistent copy of the old state to the candidate volume, preserving
   application permissions for its ID map. Provision the candidate's secret
   mount, stable address, and gateway-only firewall rules.
5. Test the candidate from the gateway, including database migrations, restart,
   login, API-key rejection, and an authorized model request. Keep the old
   writer stopped throughout final state transfer and cutover.
6. Update the gateway module's backend URL, deploy it, and verify the named
   Service from allowed and denied tailnet clients. Keep the old guest and
   verified backup until the new deployment is accepted.

For rollback, do not merely boot the old image against a database migrated by
the new one. Restore a compatible state backup and account for any new writes
before switching the gateway back. Do not delete guests, clear protection, or
destroy volumes as part of an automatic cleanup step.

Native Proxmox background:
[OCI containers](https://pve.proxmox.com/pve-docs/chapter-pct.html) and
[`pct` command reference](https://pve.proxmox.com/pve-docs/pct.1.html).
These are operator-run instructions checked against the documented interfaces;
the complete workflow has not yet been executed on `pve01`.

## Revisit the declarative Tailscale module

The pinned `services.tailscale.serve` module writes a version `0.0.1`
configuration and runs `tailscale serve set-config --all`. With that format,
`"tcp:443" = "http://127.0.0.1:20128"` creates a plain-HTTP listener, not HTTPS.
The CLI's separate `--https=443` flag preserves the intended behavior.

Upstream candidates to check periodically (both open drafts when checked on
2026-10-17):

- [Tailscale PR #20116: add serve front-end protocol to config](https://github.com/tailscale/tailscale/pull/20116)
  separates listener and backend protocols and introduces configuration version
  `0.0.2`. This could enable the declarative module once the pinned Tailscale
  supports it and the NixOS module emits the appropriate version and endpoint
  representation.
- [Tailscale PR #19554: add `tls-terminated-http`](https://github.com/tailscale/tailscale/pull/19554)
  proposes a protocol specifically for declarative HTTPS-to-HTTP proxying.
  The author describes it as an untested reference patch; do not adopt it
  merely because it exists.

Related tracking issues:

- [Tailscale #18381](https://github.com/tailscale/tailscale/issues/18381):
  `set-config` turns HTTPS listeners into HTTP.
- [nixpkgs #530174](https://github.com/NixOS/nixpkgs/issues/530174):
  the corresponding `services.tailscale.serve` limitation.

Before replacing the custom gateway units, verify the HTTPS fix is released
and present in the repository's pinned dependencies, not just merged upstream. Confirm that
the generated config retains HTTPS on port 443 with an HTTP backend, survives
reapplication and reboot, and serves the dashboard over HTTPS from an authorized
tailnet client. The module uses `--all`, so also account for every other named
Service on the host rather than unintentionally replacing its configuration.
