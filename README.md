# Peponi.to

A day planner. Tasks live on a day, or in lists you name yourself.

I built this for myself. I like it. I like the [Omarchy](https://omarchy.org/) plugin. This is the age of AI — anyone with a little grind can build this, or better. You are welcome to have it.

Live site: [https://peponi.to](https://peponi.to)

The hosted site is a week on my server. After that I delete the account and the tasks. If you want to keep it, run it yourself.

- **Self-host** (this repo): your SQLite database is the data. That is how you get sync — several browsers talking to *your* instance.
- **Local only, no sync:** run it on one machine, or use the Omarchy overlay. Nothing is sent to peponi.to.
- **MIT licensed.** No payment. No subscription.

Source: [https://github.com/Nikolaos-Gkionis/todo_app](https://github.com/Nikolaos-Gkionis/todo_app)

## What it does

- **Days:** show Today only, or 2 through 7 days side by side. Drag tasks between days.
- **Rename the app:** click the title at the top (up to 30 characters). Your lists are named the same way, by clicking a tab.
- **Not Yet lists:** park work that isn’t for a day yet. Place those lists at the bottom or in a right-hand panel.
- **Settings (the cog):** five themes, four fonts, eight accent colours (160 combinations), show/hide completed, roll unfinished tasks to the next day.
- **Today mode:** a single-day view with a 15 / 25 / 45 minute timer.
- **Notes:** extra detail, sub-steps, links, images, on a task when you need them.
- **Repeat:** daily, weekly, or on days you pick.
- **Omarchy Linux:** a local overlay with no account, or sign in once to copy existing tasks onto that machine. After that, new work stays there.

Press `?` in the app for keyboard shortcuts.

## Keyboard shortcuts

Shortcuts apply when focus is not in an input, textarea, or editable field.

| Key | Action |
|-----|--------|
| `n` | New task |
| `Shift+n` | Create new list (when Not Yet panel open) |
| `y` | Toggle Not Yet panel |
| `s` | Open Settings |
| `t` | Go to Today |
| `←` `→` | Previous / Next day |
| `Shift+←` `Shift+→` | Previous / Next week |
| `c` | Open calendar picker |
| `x` | Toggle show/hide completed tasks |
| `?` | Show shortcuts help |
| `Esc` | Close panel or modal |

### In calendar picker

| Key | Action |
|-----|--------|
| `←` `→` `↑` `↓` | Move between dates |
| `Enter` `Space` | Select focused date |
| `PgUp` `PgDn` | Previous / Next month |

### In Not Yet panel

| Key | Action |
|-----|--------|
| `↑` `↓` | Move between tasks |
| `PgUp` `PgDn` | Previous / Next list (when 2+ lists) |

## Stack

Rails 8, Ruby 4.0.1, SQLite, Hotwire/Turbo + Stimulus, custom CSS. Optional email via Brevo on the hosted site.

## Run it from source

You need **Ruby 4.0.1**, Bundler, and SQLite development headers (on Arch: `sqlite`).

```bash
git clone https://github.com/Nikolaos-Gkionis/todo_app.git
cd todo_app
bin/setup --skip-server
bin/rails server
```

Or, step by step:

```bash
bundle install
bin/rails db:prepare
bin/rails server
```

Then open http://localhost:3000

That instance is yours. Accounts do not expire. Add to Home Screen against this URL if you want a PWA on this machine.

You do **not** need payment keys. Email is optional.

If you use Docker, copy `.env.example` to `.env` first (the compose file expects a `.env` file):

```bash
cp .env.example .env
docker compose up --build
```

App: http://localhost:3000

### Hosted peponi.to only

`HOSTED_EPHEMERAL=true` means accounts on that server are deleted after 7 days. Do not set this when you self-host.

### Production (my droplet)

This repo still deploys with Kamal to [https://peponi.to](https://peponi.to). You do not need Kamal to run it locally.

## Omarchy plugin

The desktop overlay lives in a separate repo: [peponi-omarchy](https://github.com/Nikolaos-Gkionis/peponi-omarchy).

```bash
omarchy plugin add https://github.com/Nikolaos-Gkionis/peponi-omarchy.git --enable
```

Rails `/api/v1` desktop endpoints for that helper stay in this repository.

## License

[MIT](LICENSE)
