# Task Days — Omarchy one-day plugin (stub)

Quickshell / Omarchy shell plugin for a **single focused day** view of the local Task Days (peponi) todo app.

> **Status:** scaffolding only. Full QML (`manifest.json`, panel/service entry points, key handlers) is owned by the plugin implementer. Do not treat this folder as complete until those land.

## Planned behavior

- One-day view (not a multi-day calendar strip)
- Navigate to previous / next day
- Open / close a bottom drawer (lists / secondary content)

## Planned keybindings (validate once implemented)

| Action | Keys (planned) |
| --- | --- |
| Previous day | `←` or `H` |
| Next day | `→` or `L` |
| Toggle bottom drawer | dedicated binding (see `TESTING.md` once finalized) |

## Install / validate

See **[TESTING.md](./TESTING.md)** for install, reload, and keyboard checks.

## Reference

- Omarchy plugins: `~/.config/omarchy/plugins/`
- Shell config: `~/.config/omarchy/shell.json`
- Pattern reference: `37signals.hey` plugin under `~/.config/omarchy/plugins/`
