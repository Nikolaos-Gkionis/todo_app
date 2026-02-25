# Making Todo-it More TeuxDeux-like

An opinion on how to improve the Todo-it app to align with [TeuxDeux](https://teuxdeux.com/)'s calm, minimal workflow and user control - while keeping the handwritten notebook style and templates.

## UI and Layout

- **Day/week view** – Add a TeuxDeux-style day columns or week view as an optional layout next to the current "list of pages" model. Keep pages/templates as a core concept, but support a daily planner view.
- **Simpler navigation** – Reduce visual noise: subtle navigation, fewer chrome elements, and a more "empty canvas" feel.
- **Rollover behavior** – Option for unfinished today-items to roll over to the next day automatically (configurable).

## Flexibility and Options

- **Settings / preferences**
  - Font choice (e.g. handwritten vs. formal in-app)
  - Default view (list vs. day vs. week)
  - Rollover on/off
  - Reminder/notification preferences (optional, TeuxDeux-style "unintrusive")
- **Recurring tasks** – Daily/weekly/monthly repeat patterns for routine items.
- **Someday / goals** – A dedicated area for long-term goals or bucket lists that live below day-to-day tasks.
- **Templates** – Keep and expand; allow "start from template" for weekly planning, projects, etc.

## Workflow

- **No due dates** – Keep Todo-it's "no due dates" philosophy, but offer optional soft dates (e.g. "suggested for today") instead of hard deadlines.
- **Calm aesthetics** – Maintain notebook themes; consider lighter backgrounds, more whitespace, and softer interactions.
- **Reduced notifications** – Optional daily digest rather than per-task notifications.

## Implementation Requirements

- New settings model or user preferences (font, view, rollover, reminders)
- Optional "date" or "someday" semantics for todos
- New view components for day/week layout
- Recurrence logic for recurring tasks
