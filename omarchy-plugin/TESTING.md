# Testing — Omarchy one-day Task Days plugin

Short checklist to install and validate the plugin on Omarchy (Quickshell). Update key names here if the implementer finalizes different bindings.

## Prerequisites

- Omarchy with Quickshell / `omarchy-shell`
- This repo checked out on branch `feature/omarchy-one-day-plugin`
- Plugin sources present under `omarchy-plugin/` (beyond this stub) **or** already installed under `~/.config/omarchy/plugins/`

## 1. Pull the test branch

```bash
cd /home/nikolaos/Documents/GitHub/todo_app
git fetch origin
git checkout feature/omarchy-one-day-plugin
git pull --ff-only origin feature/omarchy-one-day-plugin
```

## 2. Install / link the plugin

Once the implementer ships a full plugin tree (e.g. `manifest.json` + QML):

**Option A — copy into the user plugins dir**

```bash
# Replace PLUGIN_ID with the id from manifest.json (e.g. peponi.oneday)
PLUGIN_ID="peponi.oneday"   # update when known
mkdir -p ~/.config/omarchy/plugins
rsync -a --delete ./omarchy-plugin/ ~/.config/omarchy/plugins/"$PLUGIN_ID"/
```

**Option B — Omarchy CLI** (preferred when the plugin is published as a git URL)

```bash
# Example shape — adjust URL / id when available
omarchy plugin add <plugin-git-url> --enable
# or, for a local checkout already under ~/.config/omarchy/plugins/<id>:
# omarchy plugin enable <PLUGIN_ID>
```

Enable the widget in the bar / shell if required (`omarchy bar ...` or `~/.config/omarchy/shell.json`).

## 3. Reload the shell

```bash
omarchy-shell shell rescanPlugins
# If keys or panel still look stale:
omarchy restart shell
```

Saving files under `~/.config/omarchy/plugins/` normally hot-reloads; use the commands above if something does not apply.

## 4. Validate day navigation

1. Open the plugin panel / one-day view (bar click or documented open key).
2. Note the focused date.
3. Press **Left arrow** or **H** → previous day.
4. Press **Right arrow** or **L** → next day.
5. Confirm the header / task list updates for the new day (not a multi-day strip).

## 5. Validate bottom drawer

1. With the one-day view focused, press the **bottom-drawer toggle** key (finalize in plugin README; expected: a single toggle, open then close).
2. Confirm a drawer slides up from the bottom with secondary content (e.g. lists).
3. Press the same key again → drawer closes.
4. Optional: verify focus returns to the day view and day-left / day-right still work with the drawer closed.

## 6. Smoke checks

- [ ] Plugin loads without Quickshell errors (`journalctl --user -u` / shell logs as available)
- [ ] Day-left / day-right change the focused day
- [ ] Bottom drawer opens and closes
- [ ] No conflict with global Hyprland binds that steal ←/→/H/L when the panel is focused
- [ ] `omarchy restart shell` still shows the plugin

## Notes for implementers

This branch may only contain stubs until the sibling agent finishes QML. Prefer updating **this file** and the short key table in `README.md` rather than rewriting both with conflicting large docs.
