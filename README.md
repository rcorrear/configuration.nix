# configuration.nix

NixOS and Home Manager configurations for multiple Linux and macOS systems using [den](https://github.com/vic/den) and [flake-parts](https://github.com/hercules-ci/flake-parts).

## Quickstart

- Inspect outputs: `nix flake show`
- Regenerate flake.nix: `nix run .#write-flake`
- NixOS rebuild: `sudo nixos-rebuild switch --flake .#ok1ebf`
- nix-darwin rebuild: `darwin-rebuild switch --flake .#lion`

## Structure

```text
.
├── hosts/            # Per-machine configurations
│   ├── all-platforms/    # Shared cross-platform config
│   ├── lion/             # macOS (aarch64-darwin)
│   └── ok1ebf/           # Primary workstation (x86_64-linux)
├── modules/
│   ├── aspects/      # Composable configuration aspects
│   │   ├── hosts/        # Host-specific aspects
│   │   ├── nixos/        # NixOS base configuration
│   │   └── users/        # User configurations
│   ├── den.nix       # Den configuration
│   ├── dendritic.nix # Dendritic system builder
│   ├── devshell.nix  # Development shell
│   └── inputs.nix    # Flake inputs passthrough
└── packages/         # Custom package definitions
```

## Key Features

- **Nix Flakes** with den and flake-parts for project organization
- **Home Manager** for declarative user environments
- **Secureboot** via Lanzaboote
- **Stylix** for consistent theming
- **1Password** secrets integration via opnix
- **Tailscale** VPN across all systems
