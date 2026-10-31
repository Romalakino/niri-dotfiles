#!/usr/bin/env bash
# install.sh — deploy niri + noctalia dotfiles to $HOME
# Usage: ./install.sh [--dry-run]
set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
HOME_DIR="$HOME"

deploy() {
  local src="$1" dst="$2"
  if $DRY_RUN; then
    echo "[dry-run] $src → $dst"
  else
    mkdir -p "$(dirname "$dst")"
    if [[ -e "$dst" && ! -e "$dst.dotfiles-backup" ]]; then
      mv "$dst" "$dst.dotfiles-backup"
      echo "  backed up existing: $dst → $dst.dotfiles-backup"
    fi
    cp -r "$src" "$dst"
    echo "  ✓ $dst"
  fi
}

echo "=== Niri + Noctalia Dotfiles Installer ==="
echo "Source: $REPO_DIR"
echo "Target: $HOME_DIR"
echo ""

# --- Niri ---
echo "[niri]"
deploy "$REPO_DIR/config/niri" "$HOME_DIR/.config/niri"

# --- Noctalia shell config ---
echo "[noctalia config]"
deploy "$REPO_DIR/config/noctalia/config.toml" "$HOME_DIR/.config/noctalia/config.toml"

# --- Noctalia state (transparency, blur, plugins, theme) ---
echo "[noctalia state]"
deploy "$REPO_DIR/local/state/noctalia/settings.toml" "$HOME_DIR/.local/state/noctalia/settings.toml"
deploy "$REPO_DIR/local/state/noctalia/state.toml" "$HOME_DIR/.local/state/noctalia/state.toml"

# --- Custom Noctalia plugins ---
if [[ -d "$REPO_DIR/noctalia-plugins" ]]; then
  echo "[noctalia plugins (vlad-dev source)]"
  deploy "$REPO_DIR/noctalia-plugins" "$HOME_DIR/dev/noctalia-plugins"
  echo "  ⚠ Ensure plugin source path in settings.toml points to: $HOME_DIR/dev/noctalia-plugins"
fi

# --- Alacritty ---
echo "[alacritty]"
deploy "$REPO_DIR/config/alacritty" "$HOME_DIR/.config/alacritty"

# --- Kitty theme ---
if [[ -d "$REPO_DIR/config/kitty" ]]; then
  echo "[kitty]"
  deploy "$REPO_DIR/config/kitty" "$HOME_DIR/.config/kitty"
fi

# --- Foot theme ---
if [[ -d "$REPO_DIR/config/foot" ]]; then
  echo "[foot]"
  deploy "$REPO_DIR/config/foot" "$HOME_DIR/.config/foot"
fi

# --- Btop theme ---
if [[ -d "$REPO_DIR/config/btop" ]]; then
  echo "[btop]"
  deploy "$REPO_DIR/config/btop" "$HOME_DIR/.config/btop"
fi

# --- EasyEffects ---
echo "[easyeffects]"
deploy "$REPO_DIR/config/easyeffects/db" "$HOME_DIR/.config/easyeffects/db"
deploy "$REPO_DIR/local/share/easyeffects/output" "$HOME_DIR/.local/share/easyeffects/output"

# --- Fish shell ---
echo "[fish]"
deploy "$REPO_DIR/config/fish/config.fish" "$HOME_DIR/.config/fish/config.fish"

# --- Systemd user units ---
if [[ -d "$REPO_DIR/config/systemd/user" ]] && ls "$REPO_DIR/config/systemd/user/"* &>/dev/null; then
  echo "[systemd user units]"
  deploy "$REPO_DIR/config/systemd/user" "$HOME_DIR/.config/systemd/user"
  if ! $DRY_RUN; then
    systemctl --user daemon-reload
    echo "  systemd daemon reloaded"
  fi
fi

# --- Local bin scripts ---
echo "[local/bin scripts]"
for f in "$REPO_DIR/local/bin/"*; do
  [[ -f "$f" ]] || continue
  deploy "$f" "$HOME_DIR/.local/bin/$(basename "$f")"
  chmod +x "$HOME_DIR/.local/bin/$(basename "$f")" 2>/dev/null || true
done

# --- Custom .desktop files ---
if [[ -d "$REPO_DIR/local/share/applications" ]] && ls "$REPO_DIR/local/share/applications/"*.desktop &>/dev/null; then
  echo "[desktop entries]"
  for f in "$REPO_DIR/local/share/applications/"*.desktop; do
    deploy "$f" "$HOME_DIR/.local/share/applications/$(basename "$f")"
  done
fi

# --- XDG dirs ---
if [[ -f "$REPO_DIR/config/user-dirs.dirs" ]]; then
  echo "[user-dirs.dirs]"
  deploy "$REPO_DIR/config/user-dirs.dirs" "$HOME_DIR/.config/user-dirs.dirs"
fi

echo ""
echo "=== Done! ==="
echo ""
echo "Next steps:"
echo "  1. Review ~/.config/niri/cfg/display.kdl — adjust output name/mode for your monitor"
echo "  2. If wallpaper video path differs, edit ~/.config/niri/cfg/autostart.kdl"
echo "  3. Re-login or run: niri msg action load-config-file"
echo "  4. Install missing packages (see README.md)"
