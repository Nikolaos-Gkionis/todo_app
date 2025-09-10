# Rails Todo App — Priority, Sequenced Plan (Rails 8.2 built-in auth)

**Purpose:** A developer-facing, step-by-step plan you can paste into Cursor. Uses Rails **8.2** built‑in authentication generator (no Devise) and Tailwind CSS, SQLite for development, and a hosted subdomain for production.

---

## Table of contents
1. Assumptions & stack
2. Must-haves (prioritised)
3. High-level timeline estimate
4. Step-by-step implementation (sequenced, copyable commands + file edits)
5. UI & styling details (fonts, dotted background, hand-drawn ticks/boxes, write effect)
6. Projects integration + carousel
7. Authentication (Rails 8.2 in-box) — generator + add sign-up flow
8. Testing & polish
9. Deployment & subdomain setup
10. Cursor checklist (task list you can tick)

---

## 1) Assumptions & stack
- Rails 8.2 (local dev uses SQLite)
- Ruby >= recommended for Rails 8.2
- Tailwind CSS for styling (Rails `--css=tailwind` option)
- Minimal JS for interactions (Stimulus + a small carousel lib or CSS scroll-snap)
- Hosting: Fly.io or Render (you can keep SQLite for staging on some hosts, but Postgres is recommended for production if you expect many users)

---

## 2) Must-haves (prioritised)
1. Rails + Tailwind setup (foundation)
2. SQLite database (development) + migrations
3. Rails 8.2 built-in authentication generator (sessions + passwords)
4. Sign-up/registration flow (extend generator)
5. Projects model + association to todos
6. Todo model + CRUD
7. Dotted background across app UI
8. Pen / handwritten font (global)
9. Hand-drawn checkboxes + ticks (SVG assets)
10. Write/draw-in effect on new todos (SVG stroke or typing animation)
11. Project organiser / carousel UI
12. Publish on a subdomain (DNS + host)


---

## 3) High-level timeline estimate (idea → hosted app)
**Total:** ~2 weeks (rough) — **20–40 hours** depending on polish and testing.
- Foundations (Rails, Tailwind, DB, generator): 1–2 days
- Core models + CRUD (todos/projects): 1–2 days
- Auth & registration: 0.5–1 day (generator + small registration controller)
- Styling (fonts, dotted BG, hand-drawn checkboxes): 2–3 days
- Write effect & animations: 1–2 days
- Project carousel & polish: 1–2 days
- Deployment & subdomain: 0.5–1 day
- Buffer / bugfixing & tests: 1–2 days

> If you want a tighter estimate, tell me how polished the animations must be and whether you will provide custom hand-drawn SVGs (ticks/boxes) or want placeholders.

---

## 4) Step-by-step implementation (sequenced)
> Run these commands in order. Paste into a terminal in your project folder / Cursor terminal.

### A — Create app & base
```bash
# create rails app with tailwind and sqlite
rails new todo_app --css=tailwind --database=sqlite3
cd todo_app
bin/rails db:create db:migrate
```

### B — Install & verify Tailwind
(If using default Rails 8 `--css=tailwind`, this will be wired up.)
```bash
bin/rails server
# open http://localhost:3000 to confirm Tailwind styles load
```

### C — Generate core models
```bash
# Project and Todo models
bin/rails generate model Project name:string user:references
bin/rails generate model Todo title:string notes:text completed:boolean project:references position:integer
bin/rails db:migrate
```

### D — Basic scaffolding / controllers (minimal)
```bash
bin/rails generate controller Projects index show new edit
bin/rails generate controller Todos index show new edit
```
Implement basic controllers and views. Keep views minimal — we'll style them later.

### E — Run the Rails 8.2 built-in authentication generator (in‑box)
```bash
# from project root
bin/rails generate authentication
bin/rails db:migrate
```
> This scaffolds the `User` model, `Session` pieces, password reset mailer, and helpers for handling sessions. (We will add sign up/registration below.)

### F — Wire associations to user
Edit the generated `User` model: ensure
```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_many :projects, dependent: :destroy
  # has_secure_password added by generator (password_digest)
end
```
Update `Project` and `Todo` models to `belongs_to :user` where appropriate (projects belong to user; todos belong to projects — you may scope access too).

### G — Add registrations (sign up) — small controller + routes
Create a `RegistrationsController` so users can sign up. Example minimal controller:

```ruby
# app/controllers/registrations_controller.rb
class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      start_new_session_for @user
      redirect_to projects_path, notice: 'Welcome! Your account was created.'
    else
      flash.now[:alert] = @user.errors.full_messages.join("\n")
      render :new
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
```

Add routes in `config/routes.rb`:
```ruby
resource :session, only: [:new, :create, :destroy]
resources :passwords, only: [:new, :create, :edit, :update], param: :token
resource :sign_up, controller: :registrations, only: [:new, :create]
root to: 'projects#index'
```

> The generator provides `start_new_session_for` and `allow_unauthenticated_access` helpers — use them to initialise session after sign-up.

### H — Protect resources so each user sees only their data
In ApplicationController (or a concern), require authentication:
```ruby
class ApplicationController < ActionController::Base
  before_action :require_authenticated_user!
end
```
For pages that let public access (landing), add `allow_unauthenticated_access` in controllers.

When querying projects/todos, scope to `current_user.projects` etc.

### I — Todos UI & CRUD
- Add basic controllers and CRUD actions for `todos` nested under `projects` (e.g. `projects/:project_id/todos`).
- Add position column (already added) to allow ordering inside projects.

### J — Project organiser & carousel
Option A: **CSS-only scroll-snap** (lightweight)
- Markup: horizontal list of project cards inside a container with `overflow-x: auto; scroll-snap-type: x mandatory;` and each card `scroll-snap-align: center`.

Option B: **Swiper / Splide** if you want mobile swipe gestures and pagination.

I recommend starting with scroll-snap and upgrading to Swiper only if you need better UX.

### K — Add UI assets & styling (fonts, dotted background, checkboxes)
(See section 5 for exact code snippets.)

### L — Write effect & ticks animation
(See section 5 for sample CSS/SVG + JS for typing/draw-in effect.)

### M — Tests & QA
- Add model tests for associations and validations.
- Add a few system tests (Capybara) for auth: sign-up, sign-in, creating a project, creating a todo, checking a todo.

### N — Deployment & Subdomain
(See section 9 for full steps.)

---

## 5) UI & styling details (copyable snippets)
### A — Handwritten font (Tailwind)
Add the font in `app/assets/stylesheets/application.tailwind.css` or via `app/javascript/styles` depending on setup. Example using a Google font (replace with your preferred pen script):

1. Add to `app/views/layouts/application.html.erb` head:
```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Gloria+Hallelujah&display=swap" rel="stylesheet">
```

2. Extend Tailwind in `tailwind.config.js`:
```js
module.exports = {
  content: ["./app/**/*.html.erb", "./app/helpers/**/*.rb", "./app/javascript/**/*.js"],
  theme: {
    extend: {
      fontFamily: {
        handwriting: ["'Gloria Hallelujah'", 'cursive']
      }
    }
  }
}
```

Use `class="font-handwriting"` on containers or set `body { @apply font-handwriting }` in your main stylesheet.

### B — Dotted background (SVG data URI)
Add this CSS to a global stylesheet (or via Tailwind `@layer base`):

```css
:root {
  --dots: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='20' height='20' viewBox='0 0 10 10'><circle cx='1' cy='1' r='0.8' fill='%23f1f1f1'/></svg>");
}

body {
  background-image: var(--dots);
  background-size: 20px 20px;
}
```
Tune colors and opacity as needed.

### C — Hand-drawn checkboxes & ticks (SVG)
Use an `<button>` or `<label>` with an inline SVG so you can animate the stroke.

Example HTML (erb):
```erb
<label class="todo-checkbox">
  <input type="checkbox" class="sr-only" data-action="change->todo#toggle">
  <svg viewBox="0 0 24 24" width="22" height="22" aria-hidden>
    <rect x="2" y="2" width="20" height="20" rx="3" ry="3" stroke="currentColor" fill="none" stroke-width="1.5" class="box" />
    <path d="M6 12l4 4 8-8" fill="none" stroke="currentColor" stroke-width="2" class="tick" stroke-linecap="round" stroke-linejoin="round" />
  </svg>
</label>
```

CSS to make it feel hand-drawn (rough): add a subtle `filter: url(#rough)` or use an SVG stroke-dasharray animation to draw the tick. Or use hand-crafted SVG paths exported from a drawing tool.

### D — Write / draw-in effect
Two approaches:
1. **SVG stroke-dasharray** (for text converted to SVG or for the tick path) — animate `stroke-dashoffset` to reveal the stroke.
2. **JS typing effect** (for text): simple Stimulus controller that reveals characters with a timeout.

Minimal Stimulus typing controller (paste into `app/javascript/controllers/typing_controller.js`):
```js
import { Controller } from '@hotwired/stimulus'
export default class extends Controller {
  static values = { text: String }
  connect() {
    const el = this.element
    const text = this.textValue || el.textContent
    el.textContent = ''
    let i = 0
    const interval = setInterval(() => {
      el.textContent += text[i++] || ''
      if (i >= text.length) clearInterval(interval)
    }, 16) // ~60fps per char: tweak for handwriting speed
  }
}
```
Use `data-controller="typing"` on elements you want typed in.

---

## 6) Projects integration + carousel (detailed)
### Database & models
We already generated `Project` and `Todo` models. Recommended fields:
- `Project`: `name:string`, `description:text`, `user:references`, `cover_color:string` (optional)
- `Todo`: `title:string`, `notes:text`, `completed:boolean`, `project:references`, `position:integer`

### UI: Cards + scroll-snap
Markup example:
```erb
<div class="projects-carousel overflow-x-auto scroll-snap-x py-4">
  <% @projects.each do |project| %>
    <div class="project-card inline-block scroll-snap-align-center p-4 mr-4 rounded-xl shadow-lg">
      <h3 class="font-handwriting text-xl"><%= project.name %></h3>
      <p class="text-sm"><%= project.todos.count %> todos</p>
    </div>
  <% end %>
</div>
```
Tailwind helper classes: `overflow-x-auto`, `whitespace-nowrap`, `scroll-snap-type: x mandatory`, and set cards with `inline-block`.

Add navigation controls (prev/next) that programmatically scroll the container by card width.

---

## 7) Authentication (Rails 8.2 in-box) — notes & code
**Use the built-in generator**: `bin/rails generate authentication`.

### What to expect from generator
- `User` model with `password_digest` and `has_secure_password` wired up.
- Session-related controllers & helper methods such as `start_new_session_for` and `allow_unauthenticated_access` to ease sign-in and access control.
- Passwords mailer & reset flow scaffolding.

### Add Sign-up
The generator intentionally leaves sign-up (registration) to the app, because sign-up flows are often bespoke. Add `RegistrationsController` as shown in the main step-by-step (section 4.G).

### Security notes
- Generator uses bcrypt/has_secure_password for password hashing.
- Keep `config.require_master_key` / credentials in mind for production email sending (password reset) and other secrets.

---

## 8) Testing & polish
- System tests: sign-up, sign-in, create project, add todo, toggle complete.
- Visual tests: check dotted background and font across pages, check checkbox/tick animations.
- Accessibility: ensure checkboxes are keyboard accessible and have aria labels.

---

## 9) Deployment & subdomain setup (concise)
**Recommended hosts**: Fly.io, Render, Railway. If you plan to keep SQLite in production, confirm host support — many hosts recommend Postgres for production. I recommend switching to Postgres for production; keep SQLite for local dev.

Basic steps:
1. Provision host (Fly / Render / Railway)
2. Push your repo, create app, set environment variables (RAILS_ENV=production, DATABASE_URL, SECRET_KEY_BASE)
3. If using Postgres in production: create DB and run `bin/rails db:migrate` on deploy
4. Add your domain's DNS entry: create a `CNAME` or `A` record pointing the subdomain `todos.example.com` to host's target. Follow host docs for exact DNS record.
5. Configure TLS (host usually provides automatic LetsEncrypt).

---

## 10) Cursor checklist (task list)
Use this list in Cursor and tick tasks off as you go.

- [ ] Create Rails app with Tailwind
- [ ] Generate models (Project, Todo)
- [ ] Run `bin/rails generate authentication`
- [ ] Add RegistrationsController and routes
- [ ] Add controllers/views for Projects and Todos
- [ ] Style global font and dotted background
- [ ] Build hand-drawn checkbox components
- [ ] Implement write/typing effect
- [ ] Create project carousel UI
- [ ] Add system tests
- [ ] Deploy to host and configure subdomain
- [ ] Final polish & accessibility checks

---

## Final notes
- This plan focuses on being practical: use the Rails 8.2 generator for the auth foundation and add a small registration controller. The rest is regular Rails + Tailwind work.

If you want, I can now:
- Convert the plan into a day-by-day 10-working-day sprint calendar (Cursor-friendly), or
- Create starter code snippets for each file change (controllers, views, Tailwind configs) inside the same document.

Tell me which next step you want and I’ll update the doc directly in Cursor.

