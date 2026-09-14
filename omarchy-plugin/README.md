# Peponi One Day — Omarchy overlay plugin

Keyboard-first **single-day** focus view for [Peponi / Task Days](https://github.com/Nikolaos-Gkionis/todo_app), as an Omarchy Quickshell **overlay** (same family as clipboard / reminders — not a tiny bar popup).

| | |
|---|---|
| **Plugin id** | `peponi.one-day` |
| **Kind** | `overlay` (`keepLoaded: true`) |
| **Install path** | `~/.config/omarchy/plugins/peponi.one-day/` |
| **Repo mirror** | `omarchy-plugin/` in this repository |

> **v1 data:** demo / static tasks only. A real Peponi CLI or API can replace `Model.js` later. Optional `service` / `bar-widget` kinds are deferred.

## Features

- One focused day (not a multi-day strip)
- ← / → to step days; `t` jumps to today
- `y` toggles a **Not Yet** bottom drawer (in-overlay UI state — not a second layer-shell)
- Exclusive keyboard focus while open (TUI-in-the-shell)

## Files

```
manifest.json      plugin identity + overlay entry point
Overlay.qml        fullscreen layer-shell + keys + day state
DayView.qml        task list for the selected date
BottomDrawer.qml   Not Yet slide-up panel
Model.js           date helpers + demo tasks / Not Yet items
README.md          this file
TESTING.md         install + smoke checklist
```

## In-overlay keybindings

These work only while the overlay has focus (`WlrKeyboardFocus.Exclusive`):

| Key | Action |
|-----|--------|
| `←` | Previous day |
| `→` | Next day |
| `y` | Toggle Not Yet bottom drawer |
| `t` | Jump to today |
| `↑` / `↓` | Move among tasks (or Not Yet rows when drawer is open) |
| `Esc` | Close help if open → close drawer if open → else dismiss overlay |
| `?` | Shortcuts help |

Bare arrows are **not** bound in Hyprland — that would fight every other app.

## Optional global Hyprland binds

Suggested chords from the design doc **collide** with stock Omarchy defaults:

| Chord | Already used for |
|-------|------------------|
| `SUPER + CTRL + O` | Toggle menu |
| `SUPER + CTRL + LEFT/RIGHT` | Move grouped window focus |

**Do not add those** without unbinding first. Safer alternatives (check with `omarchy menu keybindings --print` before editing `~/.config/hypr/bindings.lua`):

```lua
-- Example only — verify no collision, then add to ~/.config/hypr/bindings.lua
o.bind("SUPER + ALT + O", "Peponi one day", "omarchy-shell shell toggle peponi.one-day '{}'")
o.bind("SUPER + ALT + LEFT", "Peponi previous day", "omarchy-shell shell call peponi.one-day prevDay ''")
o.bind("SUPER + ALT + RIGHT", "Peponi next day", "omarchy-shell shell call peponi.one-day nextDay ''")
o.bind("SUPER + ALT + Y", "Peponi Not Yet", "omarchy-shell shell call peponi.one-day toggleDrawer ''")
```

This plugin does **not** modify Hyprland config for you.

## Install (local checkout)

```bash
# From the todo_app repo
rsync -a --delete ./omarchy-plugin/ ~/.config/omarchy/plugins/peponi.one-day/

omarchy plugin validate ~/.config/omarchy/plugins/peponi.one-day
omarchy-shell shell rescanPlugins
omarchy plugin enable peponi.one-day
```

Enable puts `{ "id": "peponi.one-day" }` into `~/.config/omarchy/shell.json` → `plugins[]`. It does **not** change your bar layout. (Do not pass `--yes` — that flag is treated as a bar placement option.)

## Open / test

```bash
omarchy-shell shell ping
omarchy-shell shell toggle peponi.one-day '{}'
# shell call always needs a third arg (use empty string when unused)
omarchy-shell shell call peponi.one-day prevDay ''
omarchy-shell shell call peponi.one-day nextDay ''
omarchy-shell shell call peponi.one-day toggleDrawer ''
omarchy-shell shell hide peponi.one-day
```

`keepLoaded: true` means some code edits need `omarchy restart shell` to fully apply.

## Optional layer rule

If the compositor fade looks wrong, add under `~/.config/hypr/` (never `/usr/share/omarchy/`):

```lua
hl.layer_rule({ match = { namespace = "peponi-one-day" }, no_anim = true, animation = "none" })
```

Then `hyprctl reload` and `hyprctl configerrors`.

## Later (not in v1)

- `service` kind for shared day model / live fetch
- `bar-widget` badge + click-to-summon (HEY pattern)
- Real Peponi CLI / HTTP backend instead of demo data in `Model.js`

See also: `docs/omarchy-one-day-plugin-design.md` and **[TESTING.md](./TESTING.md)**.
