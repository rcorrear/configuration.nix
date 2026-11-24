# Container image workflow

Named images share one build, validation, and export interface. Run commands
from this repository on the image's supported platform (currently x86_64 Linux):

```sh
rtk nix run .#build-image -- 9router
rtk nix run .#check-image -- 9router
rtk nix run .#copy-image -- 9router \
  "oci-archive:$HOME/9router.oci.tar:9router"
rtk nix run .#check-image -- --archive "$HOME/9router.oci.tar" 9router
```

`nix build-image` is not a built-in Nix subcommand; `nix run .#build-image`
is the portable equivalent. Use `--help` to list registered image names.
Currently `9router` is registered. This interface does not
yet migrate Radarr, Sonarr, or any other deployed service.

- **Build:** builds `<name>-image` without creating a `result` link. Its closure
  includes the application runner; there is no separate runner build step.
- **Check:** builds `checks.<system>.image-<name>`. The aggregate includes shared
  metadata and OCI archive validation plus the image's registered smoke tests.
  All component checks also appear in `nix flake check`; scripts do not need to
  enumerate platform-specific attribute paths.
- **Copy:** forwards destination and Skopeo options to the image's `copyTo`
  helper. It neither deploys a guest nor changes running containers.
- **Check an exported archive:** `check-image --archive PATH NAME` evaluates
  the registered contract and checks that exact local artifact without
  extracting or executing it. It does not rerun application smoke tests.

The wrappers use the current checkout by default. To select another flake,
pass `--flake PATH_OR_REFERENCE` **before** the image name. Build/check accept
extra Nix build flags after the name:

```sh
rtk nix run .#build-image -- --flake /path/to/checkout 9router --show-trace
```

Registry export is explicit:

```sh
# Only after selecting/authorizing the destination and authenticating externally:
rtk nix run .#copy-image -- 9router docker://registry.example.org/team/9router:VERSION
```

Never put credentials in command arguments, image configuration, or repository
files. The command does not log in to registries or authorize publication.

## Register another application

`modules/container-images.nix` defines the per-system `proxmoxImages` option.
An application module registers a nix2container image, its runtime contract,
and application-specific checks. For example, inside its `perSystem` definition:

```nix
proxmoxImages.example = {
  image = application.image;
  contract = {
    user = "1000:1000";
    entrypoint = [ (lib.getExe application.runner) ];
    ports = [ "8080/tcp" ];
    volumes = [ "/var/lib/example" ];
    forbiddenEnvironment = [ "APP_SECRET" "OP_SERVICE_ACCOUNT_TOKEN" ];
    requiredMembers = [ "etc/passwd" "etc/group" ];
  };
  tests.smoke = applicationSmokeTest;
};
```

Only register it on supported systems. Registrations automatically produce
`<name>-image`, `image-<name>-metadata`, `image-<name>-archive`, application
checks such as `image-<name>-smoke`, and the aggregate `image-<name>`.
The metadata/archive test names are reserved for shared validation.

Shared validation checks startup identity, entrypoint, declared ports/volumes,
forbidden environment variables, required files, and safe layer paths. Nix
store symlink preservation is required by default; `requireNixSymlinks = false`
supports images without such symlinks. Absolute archive member names, traversal,
and unsafe hardlink targets are always rejected. Absolute symlink targets are
valid container filesystem paths and are preserved.

The registry removes duplicated infrastructure, not application-specific
requirements. Each new service still needs a real HTTP/functional smoke test,
persistent-state ownership, secret provisioning, network policy, and a reviewed
Proxmox deployment/migration procedure.

9Router's VM smoke check exercises SecretSpec startup, HTTP authentication
behavior, shutdown, restart, and the privilege boundary.
