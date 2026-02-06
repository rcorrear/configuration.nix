#!/usr/bin/env bash
set -uo pipefail

# LXC hosts to compare
HOSTS=(hass plex prowlarr radarr sonarr tailscale files)

# Output directory
OUT_DIR="${1:-./closure-diffs}"
mkdir -p "$OUT_DIR"

# Track failures
FAILED_HOSTS=()

for host in "${HOSTS[@]}"; do
	echo "=== Processing $host ==="

	# Build local configuration
	echo "Building .#nixosConfigurations.$host..."
	if ! nix build ".#nixosConfigurations.$host.config.system.build.toplevel" -o "result-$host"; then
		echo "ERROR: Failed to build configuration for $host, skipping..."
		FAILED_HOSTS+=("$host (build failed)")
		continue
	fi

	# Get remote path
	echo "Getting remote path from $host..."
	if ! REMOTE_PATH=$(ssh "$host" readlink -f /run/current-system 2>"$OUT_DIR/$host.ssh.err"); then
		SSH_ERR=$(cat "$OUT_DIR/$host.ssh.err")
		echo "ERROR: Failed to connect to $host: $SSH_ERR"
		FAILED_HOSTS+=("$host (ssh failed)")
		rm -f "result-$host"
		continue
	fi

	# Copy remote to local store
	echo "Copying remote closure (this may take a while)..."
	if ! nix copy --from "ssh://$host" "$REMOTE_PATH" --no-check-sigs 2>"$OUT_DIR/$host.copy.err"; then
		echo "WARNING: Failed to copy closure for $host (see $OUT_DIR/$host.copy.err)"
		FAILED_HOSTS+=("$host (copy failed)")
		rm -f "result-$host"
		continue
	fi

	# Generate diff
	echo "Generating diff..."
	if ! nix store diff-closures "$REMOTE_PATH" "./result-$host" >"$OUT_DIR/$host.diff" 2>"$OUT_DIR/$host.err"; then
		echo "WARNING: Diff failed for $host (see $OUT_DIR/$host.err)"
		FAILED_HOSTS+=("$host (diff failed)")
		rm -f "result-$host"
		continue
	fi

	# Show removals
	echo "Removals for $host:"
	grep '→ ∅' "$OUT_DIR/$host.diff" || echo "  (none)"
	echo ""

	# Cleanup result symlink
	rm -f "result-$host"
done

echo "=== Done! Diffs saved to $OUT_DIR/ ==="

if [[ ${#FAILED_HOSTS[@]} -gt 0 ]]; then
	echo ""
	echo "=== Failed hosts ==="
	for failed in "${FAILED_HOSTS[@]}"; do
		echo "  - $failed"
	done
	exit 1
fi
