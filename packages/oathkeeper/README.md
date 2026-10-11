# Oathkeeper modules

Reusable NixOS, service-class, and MicroVM modules for the Ory Oathkeeper
authentication gateway. These files were migrated from Omni commit
`747d5638471d1f43006db3db9015e528db2b61c3`.

The `services.omni.oathkeeper` and service-class `omni.oathkeeper` option names
are retained for protocol compatibility. They do not create a private Omni
dependency.

- `module.nix` is the NixOS wrapper.
- `service.nix` is the service-class implementation.
- `microvm.nix`, called with `{ inputs; }`, exports
  `mkOathkeeperMicrovm` and `mkOathkeeperMicrovmModule`.
- `runtime-secrets.nix` renders the exact generated files using systemd credentials
  during Oathkeeper startup. The service owns its `0700` runtime directory and
  `0600` configuration files; it does not search the Nix store for templates.

The flake exposes these through `nixosModules.oathkeeper`,
`nixosModules.microvm-host`, `lib.mkOathkeeperMicrovm`,
`lib.mkOathkeeperMicrovmModule`, and the parameterized
`lib.oathkeeperService`.

## Tests

On Linux, run the service and MicroVM smoke tests with:

```sh
nix build .#checks.x86_64-linux.oathkeeper .#checks.x86_64-linux.oathkeeper-microvm
```

The tests use local fixtures, not real Ory sessions or 1Password credentials.
The MicroVM test puts its HTTP Ory fixture behind an HTTPS proxy with an ephemeral
test CA and server key, then installs only that CA in the guest. They cover
authentication and header forwarding, failure handling, runtime secrets, and both
host-managed and standalone MicroVM configuration. The MicroVM test boots with
QEMU software emulation so it does not require nested KVM.
