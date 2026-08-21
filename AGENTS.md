# AGENTS.md

Repository guidance for agents working on this Nix flake.

<!-- headroom:rtk-instructions -->
# RTK (Rust Token Killer)

Prefix shell commands with `rtk`. It reduces command output without changing
behavior. If a command has no RTK filter, it is passed through unchanged.

Examples:

```bash
rtk ls <path>
rtk read <file>
rtk grep <pattern>
rtk git status
rtk git diff
rtk devenv shell check
```

Prefix each command in a chain. Use a raw command for debugging when RTK would
hide the information needed. Use `rtk proxy <command>` to run an unfiltered
command while tracking usage.
<!-- /headroom:rtk-instructions -->

## Validation

Run:

```bash
rtk devenv shell check
```

The check script runs formatting with `--fail-on-change` and the repository's
pre-commit hooks. Do not use a formatter as a substitute for the full check.

## Den

Den is pinned in `flake.lock`. Before changing Den configuration, inspect the
pinned `inputs.den` source and the relevant files under `modules/`; do not
guess option names or copy unpinned documentation.

Use the patterns already established in this repository:

- `den.aspects.<name>` for composable configuration.
- `den.default` for configuration shared by all entities.
- `den.batteries.*` (or the existing `den._.*` spelling) for built-in helpers.
- `den.schema.*` for entity metadata and shared schema configuration.
- `den.hosts` and `den.homes` for system and standalone-home declarations.
- `den.schema.hm-host.includes` for Home Manager host integration.

Prefer direct parametric aspect includes such as `{ host, user }: { ... }` when
the existing source supports them. Keep Den API explanations out of this file;
the pinned source is the authority.

## Repository structure

- `modules/aspects/`: composable host, user, and shared aspects.
- `modules/`: Den setup, shared modules, and module arguments.
- `hosts/`: host-specific module imports.
- `homes/`: Home Manager configuration.
- `packages/`: custom packages.

Use aspects for composable configuration attached to hosts or users. Use
ordinary modules for new options, `_module.args`, or configuration that must
always be present. Set global `_module.args` only once. See `README.md` for
the local organization rules.

## Graphify

When `/graphify` is requested, follow the installed graphify instructions.
For codebase questions, query `graphify-out/graph.json` first when it exists;
use path/explain queries for focused relationships. After modifying code, run
`rtk graphify update .` when the command is available. Use
`rtk proxy graphify update .` only when explicitly unfiltered output is needed.
