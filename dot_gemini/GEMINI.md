# Global context for Gemini CLI

## Environment
- Host OS: Bluefin-dx (uBlue / bluebuild), Fedora-based, immutable ostree. Personal image lives at `~/Projects/myos` (bluebuild recipe), repo `github.com/AsirShahid/myos`.
- Host CLI tools are installed via Homebrew (`/home/linuxbrew/.linuxbrew`), which auto-updates/upgrades on a timer. Gemini CLI itself was installed with `brew install gemini-cli`.
- Dotfiles/config are managed by chezmoi (source: `github.com/AsirShahid/dotfiles`, local source `~/.local/share/chezmoi`). This file and `~/.gemini/settings.json` are tracked there; credentials are not.
- Containers via distrobox (Arch, plus fedora-41 / ubuntu). Use only when host-native won't do.

## Conventions
- The base OS is immutable: prefer brew, flatpak, or distrobox over layering rpms; system-level changes belong in the `myos` recipe, not ad-hoc.
- npm global prefix is the read-only `/usr/local`; do not `npm install -g` on the host without a user-level prefix.
