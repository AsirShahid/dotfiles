#!/usr/bin/env bash
# ~/.config/distrobox/arch-provision.sh — tracked in chezmoi.
# Idempotent provisioning for the "Arch" distrobox: this is the single source of truth
# for everything installed in the box. Safe to re-run; `chezmoi apply` runs it for you.
#
# Recovering a box broken by an interrupted upgrade (power loss mid `paru -Syu`)?
# Don't fight it — just rebuild:  distrobox rm Arch -f && chezmoi apply
# (A populated /var/cache/pacman/pkg also lets you repair offline:
#   sudo rm -f /var/lib/pacman/db.lck && sudo pacman -Syu  # finish the interrupted txn
#   sudo pacman -S $(pacman -Qqn)                          # reinstall everything from cache )
set -euo pipefail

log() { printf '\033[1;34m::\033[0m %s\n' "$*"; }

############################ 1. Base system + keyring ###########################
# Always a full -Syu (never a partial -Sy) — partial upgrades are their own footgun.
log "Refreshing keyring + upgrading base, then installing repo packages"
sudo pacman-key --init >/dev/null 2>&1 || true
sudo pacman -Sy --needed --noconfirm archlinux-keyring

PACMAN_PKGS=(
  base-devel git zsh
  nodejs npm
  python python-pip python-pipx
  freetype2 libjpeg-turbo libpng libtiff   # build deps for pillow/matplotlib wheels-from-source
  htop ncdu ranger fastfetch
)
sudo pacman -Syu --needed --noconfirm "${PACMAN_PKGS[@]}"

############################ 2. AUR helper + AUR packages #######################
if ! command -v paru >/dev/null 2>&1; then
  log "Bootstrapping paru (AUR helper)"
  tmp="$(mktemp -d)"
  git clone --depth=1 https://aur.archlinux.org/paru-bin.git "$tmp/paru-bin"
  ( cd "$tmp/paru-bin" && makepkg -si --noconfirm )
  rm -rf "$tmp"
fi
AUR_PKGS=(
  opera                # Opera browser (added on request; no atuin trace, so unverified)
  # Optional extras that were on your OTHER machines (fedora/dhcp) — uncomment to add here:
  #   matugen-bin        # material-you theming
)
if ((${#AUR_PKGS[@]})); then
  log "Installing AUR packages"
  paru -S --needed --noconfirm "${AUR_PKGS[@]}"
fi

############################ 3. Python apps via pipx ############################
# pipx into a BOX-LOCAL prefix (not ~/.local, which is shared with the host and other
# boxes — that's why your old exported wrappers broke). Then export proper distrobox
# wrappers into ~/.local/bin so the host can call them.
export PIPX_HOME=/opt/pipx PIPX_BIN_DIR=/opt/pipx/bin
sudo install -d -o "$USER" -g "$USER" /opt/pipx
log "Installing Python apps via pipx -> $PIPX_BIN_DIR"
pipx install --force jupyterlab >/dev/null
pipx install --force ipython    >/dev/null
pipx install --force fonttools  >/dev/null        # provides ttx / pyftsubset / pyftmerge
# Data libs available inside the notebook env (pybaseball/cloudscraper aren't in repos):
pipx inject jupyterlab pandas plotly matplotlib pillow pybaseball cloudscraper debugpy >/dev/null
# Streamlit app + its libs, self-contained:
pipx install --force streamlit >/dev/null
pipx inject streamlit pandas plotly matplotlib pillow pybaseball >/dev/null

############################ 4. Node global tools ##############################
log "Installing node global tools"
sudo npm install -g pnpm >/dev/null   # sass/bun were on other machines, not this box

############################ 5. Export box tools to the host ###################
log "Exporting tools to host ~/.local/bin"
export_bin() { [ -e "$1" ] && distrobox-export --bin "$1" --export-path "$HOME/.local/bin" 2>/dev/null || true; }
export_bin "$PIPX_BIN_DIR/jupyter"
export_bin "$PIPX_BIN_DIR/jupyter-lab"
export_bin "$PIPX_BIN_DIR/ipython"
export_bin "$PIPX_BIN_DIR/ttx"
export_bin "$PIPX_BIN_DIR/streamlit"
export_bin "/usr/bin/pnpm"
# GUI app -> host application menu:
[ -e /usr/bin/opera ] && distrobox-export --app opera 2>/dev/null || true
# Note: agy / codex / hermes are intentionally NOT here — they're host-native in
# ~/.local/bin (curl-installers), survived the box break, and managing them is a host concern.
# matugen / sass / bun were on your OTHER machines (fedora/dhcp), not this box — omitted.

log "Arch box provisioned."
