#!/usr/bin/env bash
# Install Peponi One Day Omarchy helper: plugin + CLI + sign-in + bar placement + optional binds.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_SRC="$ROOT/plugin"
PLUGIN_ID="peponi.one-day"
PLUGIN_DST="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/$PLUGIN_ID"
BIN_DST="${XDG_BIN_HOME:-$HOME/.local/bin}/peponi"
BINDINGS_LUA="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/bindings.lua"

echo "==> Peponi Omarchy helper install"
echo "    source: $ROOT"

command -v rsync >/dev/null || { echo "rsync required"; exit 1; }
command -v omarchy >/dev/null || { echo "omarchy CLI required (Omarchy Linux)"; exit 1; }

mkdir -p "$(dirname "$BIN_DST")"
install -m 755 "$ROOT/bin/peponi" "$BIN_DST"
echo "    CLI → $BIN_DST"

mkdir -p "$(dirname "$PLUGIN_DST")"
rsync -a --delete "$PLUGIN_SRC/" "$PLUGIN_DST/"
echo "    plugin → $PLUGIN_DST"

if omarchy plugin validate "$PLUGIN_DST"; then
  echo "    validate: ok"
else
  echo "    validate failed" >&2
  exit 1
fi

# Rescan / enable overlay+service plugin
omarchy-shell shell rescanPlugins 2>/dev/null || true
omarchy plugin enable "$PLUGIN_ID" 2>/dev/null || omarchy plugin enable "$PLUGIN_ID" --yes 2>/dev/null || true

# --- Sign in (required for paid users) ---
echo
echo "==> Sign in to peponi.to (paid accounts only)"
if [[ -n "${PEPONI_BASE_URL:-}" ]]; then
  echo "    PEPONI_BASE_URL=$PEPONI_BASE_URL"
fi
if ! "$BIN_DST" auth login; then
  echo "Sign-in failed. Fix credentials / ensure the account is paid, then re-run:" >&2
  echo "  $BIN_DST auth login" >&2
  exit 1
fi

# --- Bar toggle placement ---
echo
echo "==> Where should the Peponi bar toggle live?"
echo "    1) left"
echo "    2) center"
echo "    3) right  (default)"
printf "Choice [1/2/3]: "
read -r choice || true
case "${choice:-3}" in
  1|left|l|L) section=left ;;
  2|center|centre|c|C) section=center ;;
  *) section=right ;;
esac

echo "    placing bar widget on: $section"
if omarchy bar put "$PLUGIN_ID" --section "$section" 2>/dev/null; then
  echo "    bar put ok"
elif omarchy bar move "$PLUGIN_ID" --section "$section" 2>/dev/null; then
  echo "    bar move ok"
else
  echo "    Could not place bar widget automatically."
  echo "    Add manually, e.g.: omarchy bar put $PLUGIN_ID --section $section"
fi

# --- Optional Hyprland SUPER+ALT binds ---
echo
echo "==> Optional global keybindings (SUPER+ALT)"
echo "    Checking for collisions..."
if command -v omarchy >/dev/null; then
  omarchy menu keybindings --print 2>/dev/null | grep -E 'SUPER \+ ALT \+ (O|Y|LEFT|RIGHT)' || echo "    (no obvious SUPER+ALT O/Y/LEFT/RIGHT hits in printout)"
fi
printf "Add SUPER+ALT O/LEFT/RIGHT/Y to %s? [y/N]: " "$BINDINGS_LUA"
read -r add_binds || true
if [[ "${add_binds:-}" =~ ^[Yy]$ ]]; then
  mkdir -p "$(dirname "$BINDINGS_LUA")"
  touch "$BINDINGS_LUA"
  if grep -q 'peponi.one-day' "$BINDINGS_LUA" 2>/dev/null; then
    echo "    bindings already mention peponi.one-day — left unchanged"
  else
    cat >> "$BINDINGS_LUA" <<'LUA'

-- Peponi One Day (desktop helper)
o.bind("SUPER + ALT + O", "Peponi one day", "omarchy-shell shell toggle peponi.one-day '{}'")
o.bind("SUPER + ALT + LEFT", "Peponi previous day", "omarchy-shell shell call peponi.one-day prevDay ''")
o.bind("SUPER + ALT + RIGHT", "Peponi next day", "omarchy-shell shell call peponi.one-day nextDay ''")
o.bind("SUPER + ALT + Y", "Peponi Not Yet", "omarchy-shell shell call peponi.one-day toggleDrawer ''")
LUA
    echo "    appended SUPER+ALT binds"
    echo "    reload Hyprland config if binds do not apply immediately"
  fi
else
  echo "    skipped keybindings"
fi

echo
echo "==> Done"
echo "    Toggle: omarchy-shell shell toggle peponi.one-day '{}'"
echo "    Or click the Peponi bar icon ($section)"
echo "    After keepLoaded edits: omarchy restart shell"
