# Peponi Omarchy helper

Standalone **Omarchy / Quickshell** desktop helper for **paid** [peponi.to](https://peponi.to) accounts.

Shows a keyboard-first **one-day** focus overlay (←/→ days, `y` Not Yet drawer) fed by a small `peponi` CLI that talks to peponi.to’s `/api/v1` desktop API.

| | |
|---|---|
| **Plugin id** | `peponi.one-day` |
| **Kinds** | `service` + `overlay` + `bar-widget` |
| **Install path** | `~/.config/omarchy/plugins/peponi.one-day/` |
| **CLI** | `~/.local/bin/peponi` |
| **Credentials** | `~/.config/peponi/credentials.json` (mode `0600`) |

> This folder is meant to become its **own git repository**. It currently lives inside the peponi.to app monorepo only for development. The Rails `/api/v1` endpoints ship with peponi.to — not with this helper.

## Requirements

- Omarchy Linux (Quickshell + `omarchy` CLI)
- A **paid** peponi.to account (`paid_at` or legacy `device_downloaded`)
- peponi.to API deployed (`/api/v1/auth/*`, `/api/v1/days/:date`, `/api/v1/not_yet`)
- `curl`, `python3`, `rsync`

## Install (interactive)

```bash
cd peponi-omarchy
./scripts/install.sh
```

The script will:

1. Install the CLI and plugin
2. Validate the plugin
3. **Prompt you to sign in** (`peponi auth login`)
4. Ask where to put the bar toggle: **left / center / right**
5. Optionally append **SUPER+ALT** Hyprland chords

Local Rails while developing:

```bash
export PEPONI_BASE_URL=http://127.0.0.1:3000
./scripts/install.sh
```

## CLI

```bash
peponi auth login
peponi auth status --json
peponi day 2026-09-14 --json
peponi not-yet --json
peponi auth logout
```

## Keybindings

**In-overlay:** `←`/`→` day · `y` Not Yet · `t` today · `Esc` close · `?` help

**Global (if install added them):**

| Chord | Action |
|-------|--------|
| `SUPER + ALT + O` | Toggle overlay |
| `SUPER + ALT + LEFT/RIGHT` | Prev / next day |
| `SUPER + ALT + Y` | Toggle Not Yet drawer |

## Demo / offline

```bash
PEPONI_DEMO=1 omarchy restart shell
```

Uses stub tasks only — skip for real sign-in testing.

## Uninstall

```bash
./scripts/uninstall.sh
```

## Extract to its own GitHub repo (you do this)

Do **not** merge this helper into peponi.to `main` as the long-term home. When ready:

1. Create an empty GitHub repo (e.g. `peponi-omarchy`).
2. Copy **only** this directory’s contents to a new folder and `git init`:

```bash
mkdir -p ~/src/peponi-omarchy
rsync -a --exclude .git ./peponi-omarchy/ ~/src/peponi-omarchy/
cd ~/src/peponi-omarchy
git init
git add .
git commit -m "Initial peponi Omarchy helper."
gh repo create peponi-omarchy --private --source=. --remote=origin --push
```

3. Deploy the Rails `/api/v1` desktop endpoints on **peponi.to** (they live in the main app, not here).
4. Point install docs at `omarchy plugin add <git-url>` once you publish.

## Layout

```
peponi-omarchy/
  bin/peponi
  scripts/install.sh
  scripts/uninstall.sh
  plugin/          # Omarchy Quickshell plugin
  docs/            # design notes
  README.md
  LICENSE
```
