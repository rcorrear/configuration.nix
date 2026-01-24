# configuration.nix

NixOS and Home Manager configurations for managing multiple Linux and macOS systems using Nix Flakes and [Snowfall Lib](https://github.com/snowfallorg/lib).

## Structure

```
.
├── systems/          # Per-machine NixOS/nix-darwin configurations
│   ├── x86_64-linux/     # Linux systems (OK1EBF workstation, media servers, etc.)
│   └── aarch64-darwin/   # macOS systems
├── homes/            # Home Manager user environment configs
│   ├── x86_64-linux/
│   ├── aarch64-darwin/
│   └── all-platforms/    # Shared cross-platform config
├── modules/          # Reusable NixOS and Home Manager modules
├── packages/         # Custom package definitions
├── overlays/         # Nix package overlays
└── shells/           # Development shell configurations
```

## Systems

### Linux (`x86_64-linux`)

- **OK1EBF** — Primary workstation with NVIDIA GPU passthrough (VFIO), Hyprland/Niri/GNOME, Ollama, and ZFS
- **files** — File server
- **hass** — Home Assistant
- **plex / sonarr / radarr / prowlarr** — Media stack
- **tailscale** — VPN gateway

### macOS (`aarch64-darwin`)

- **ferrus**, **lion**

## Key Features

- **Nix Flakes** with Snowfall Lib for project organization
- **Home Manager** for declarative user environments
- **Secureboot** via Lanzaboote
- **GPU passthrough** with VFIO/libvirt/QEMU
- **ZFS** with auto-scrub and snapshots
- **Stylix** for consistent theming across desktop environments
- **1Password** secrets integration via opnix
- **Ollama + Open WebUI** for local LLM inference
- **Tailscale** VPN across all systems
