#!/bin/sh
# Install Claude Code as a native, self-updating binary under ~/.local.
#
# We deliberately install host-native rather than relying on the Arch
# distrobox copy: the distrobox-exported ~/.local/bin/claude wrapper makes
# Claude run *inside* the container (no host systemd / rpm-ostree / brew
# visibility). The native build self-updates and sees the host directly.
#
# chezmoi runs this once and re-runs only if the file's contents change.

set -eu

# If a native install already exists, skip. The native build lives under
# ~/.local/share/claude; the distrobox wrapper does NOT, so we still install
# even when that wrapper happens to be first on PATH.
native_root="$HOME/.local/share/claude"
if command -v claude >/dev/null 2>&1; then
    resolved=$(readlink -f "$(command -v claude)" 2>/dev/null || true)
    case "$resolved" in
        "$native_root"/*)
            echo "Claude Code already installed natively; skipping."
            exit 0
            ;;
    esac
fi

echo "Installing Claude Code (native build) into ~/.local ..."
curl -fsSL https://claude.ai/install.sh | bash
