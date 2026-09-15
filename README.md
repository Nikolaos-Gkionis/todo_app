# Peponi.to

A day planner. Tasks live on a day, or in lists you name yourself. Try it on the web for 7 days, then pay once to keep using it and install it as a PWA.

Live site: [https://peponi.to](https://peponi.to)

## What it does

- **Days:** show Today only, or 2 through 7 days side by side. Drag tasks between days.
- **Rename the app:** click the title at the top (up to 30 characters). Your lists are named the same way, by clicking a tab.
- **Not Yet lists:** park work that isn’t for a day yet. Place those lists at the bottom or in a right-hand panel.
- **Settings (the cog):** five themes, four fonts, eight accent colours (160 combinations), show/hide completed, roll unfinished tasks to the next day.
- **Today mode:** a single-day view with a 15 / 25 / 45 minute timer.
- **Notes:** extra detail, sub-steps, links, images, on a task when you need them.
- **Repeat:** daily, weekly, or on days you pick.
- **Trial vs purchase:** the 7-day trial is the website. PWA install (Add to Home Screen / Install app) is after the one-time £9.99 purchase, on up to three devices. No subscription.
- **Omarchy Linux:** a free local overlay with no account, or a paid sign-in that copies your existing tasks onto that machine. After that, new work stays there.

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

Rails 8, Ruby 3.4, SQLite, Hotwire/Turbo + Stimulus, custom CSS. Payments via Polar. Email via Brevo.

## Run it locally

```bash
git clone <your-repo>
cd todo_app
bundle install
rails db:migrate
rails db:seed
rails server
```

Then open http://localhost:3000

You’ll need Polar keys in the environment for checkout (`POLAR_ACCESS_TOKEN`, `POLAR_PRODUCT_ID`, `POLAR_WEBHOOK_SECRET`). Copy from whatever env template you use on this machine.

### Docker

```bash
docker-compose up --build
```

App: http://localhost:3000

### Production

This repo deploys with Kamal to [https://peponi.to](https://peponi.to).

## Omarchy plugin

The desktop overlay lives in a separate repo: [peponi-omarchy](https://github.com/Nikolaos-Gkionis/peponi-omarchy).

```bash
omarchy plugin add https://github.com/Nikolaos-Gkionis/peponi-omarchy.git --enable
```

Rails `/api/v1` desktop endpoints for that helper stay in this repository.
