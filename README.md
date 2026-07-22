# configuration.nix

NixOS and Home Manager configurations for multiple Linux and macOS systems using [den](https://github.com/vic/den) and [flake-parts](https://github.com/hercules-ci/flake-parts).

## Quickstart

- Inspect outputs: `nix flake show`
- Regenerate flake.nix: `nix run .#write-flake`
- NixOS rebuild: `sudo nixos-rebuild switch --flake .#OK1EBF`
- nix-darwin rebuild: `darwin-rebuild switch --flake .#lion`

## Structure

```text
.
├── homes/            # Home Manager configs
│   ├── all/              # Shared home config
│   ├── darwin/           # macOS home config
│   ├── nixos/            # NixOS home config
│   └── modules/          # Home Manager-only modules (used by homes/*)
├── hosts/            # Per-machine configurations
│   ├── darwin/           # Darwin host files
│   └── nixos/            # NixOS host files
├── modules/
│   ├── aspects/      # Composable configuration aspects
│   │   ├── darwin/       # Darwin-related aspects
│   │   ├── hosts/        # Host-specific aspects
│   │   ├── nixos/        # NixOS base configuration
│   │   └── users/        # User configurations
│   ├── nixos/        # Shared NixOS modules
│   ├── den.nix       # Den configuration
│   ├── dendritic.nix # Dendritic system builder
│   └── namespace.nix # Namespace helpers
└── packages/         # Custom package definitions
```

## Home modules vs aspects

- Use `homes/modules/*` for Home Manager–only modules. These should only touch `home.*` / `programs.*` options under HM.
- Use `modules/aspects/*` when the configuration should be attached to a host (NixOS/darwin) or shared across system scopes.

## Modules vs aspects

- Use **aspects** for composable host configuration (`den.aspects.<name>.{nixos,darwin}`), i.e., “what a host should include.”
- Use **modules** (`modules/nixos/*`, `modules/*`) to define new options or `_module.args`, or for configuration that must always be present regardless of aspect includes.
- `_module.args` is global and must be set only once; avoid setting it inside aspects.

## Key Features

- **Nix Flakes** with den and flake-parts for project organization
- **Home Manager** for declarative user environments
- **Secureboot** via Lanzaboote
- **Stylix** for consistent theming
- **1Password** secrets integration via opnix
- **Tailscale** VPN across all systems
