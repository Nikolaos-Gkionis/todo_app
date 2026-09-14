# Testing — Peponi One Day (`peponi.one-day`)

Install and smoke-test the overlay plugin on Omarchy.

## Prerequisites

- Omarchy with `omarchy-shell` (Quickshell)
- Branch `feature/omarchy-one-day-plugin`
- Sources in `omarchy-plugin/` (this folder)

## 1. Install into user plugins

```bash
cd /home/nikolaos/Documents/GitHub/todo_app
rsync -a --delete ./omarchy-plugin/ ~/.config/omarchy/plugins/peponi.one-day/
```

## 2. Validate

```bash
omarchy plugin validate ~/.config/omarchy/plugins/peponi.one-day
# Expect exit 0
```

Also validate the repo mirror:

```bash
omarchy plugin validate ./omarchy-plugin
```

## 3. Enable (does not touch bar layout)

```bash
omarchy-shell shell rescanPlugins
omarchy plugin enable peponi.one-day
```

Confirm:

```bash
omarchy-shell shell listPlugins | jq '.[] | select(.id=="peponi.one-day")'
```

## 4. Open the overlay

```bash
omarchy-shell shell toggle peponi.one-day '{}'
```

You should see a centered card: **PEPONI**, today’s heading, demo tasks, and a shortcut hint line.

## 5. In-overlay keyboard checks

With the overlay focused:

| Step | Key | Expect |
|------|-----|--------|
| 1 | `←` | Previous day (heading + tasks change) |
| 2 | `→` | Next day |
| 3 | `t` | Jump back to today |
| 4 | `y` | Not Yet drawer slides up |
| 5 | `↑` / `↓` | Move among Not Yet rows |
| 6 | `y` again | Drawer closes |
| 7 | `?` | Shortcuts help |
| 8 | `Esc` | Closes help / drawer first, then overlay |

IPC while open (or to force-open):

```bash
omarchy-shell shell call peponi.one-day prevDay ''
omarchy-shell shell call peponi.one-day nextDay ''
omarchy-shell shell call peponi.one-day toggleDrawer ''
omarchy-shell shell hide peponi.one-day
```

## 6. Global binds (optional)

Stock Omarchy already uses `SUPER+CTRL+O` and `SUPER+CTRL+LEFT/RIGHT`. Prefer `SUPER+ALT+…` alternatives documented in **README.md**. Only edit `~/.config/hypr/bindings.lua` after checking:

```bash
omarchy menu keybindings --print
```

## 7. After code edits

```bash
# Hot reload often works for non-keepLoaded plugins; this overlay is keepLoaded:
omarchy restart shell
```

## Checklist

- [ ] `omarchy plugin validate` exits 0
- [ ] Plugin appears in `listPlugins` and is enabled
- [ ] Toggle shows one-day view (not multi-day)
- [ ] ← / → change the day
- [ ] `y` opens/closes bottom Not Yet drawer
- [ ] Esc closes drawer before dismissing overlay
- [ ] Bar layout in `shell.json` unchanged

## Demo data note

Tasks and Not Yet items come from `Model.js` weekday stubs. No Rails/API yet.
