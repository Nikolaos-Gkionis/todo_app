# Peponi.to — QA & debug plan (session 2026-03-27)

This document records manual and automated checks run against the local app (`rails server` on `http://127.0.0.1:3000`), security probes, bugs confirmed, fixes applied, and items worth a second pass.

---

## 1. What was tested

| Area | Method | Result |
|------|--------|--------|
| Marketing (`/`, `/pricing`) | Browser MCP | Pages load; nav links present |
| Sign up | Browser MCP | New user `qatest20260327@example.com` created; redirect to `/app` |
| App shell | Browser snapshot | Week columns, FAB, Not Yet panel (lists), settings controls, notes toolbar (Bold, Italic, Insert image, etc.) |
| Unauthenticated download | `curl -I /app/download` | `302` → `/login` (expected) |
| Token download (trial) | `curl -I /app/download/app?token=…` + DB | See bugs below |

---

## 2. Bugs confirmed (with evidence)

### 2.1 Download quota incremented without delivering a file (trial users)

**Symptom:** Hitting the download URL with a valid token while still on trial redirected to `/pricing` (correct), but `download_count` increased anyway.

**Evidence (before fix):**

- `rails runner` showed `download_count=0`, then after one `GET /app/download/app?token=…`, `after_dl_count=1` while the HTTP response was `302` → `/pricing`.

**Root cause:** `increment_download_count!` ran before the branch that sends trial users to pricing.

**Fix:** In `DownloadsController#download`, verify the token, then if `on_trial? && !device_downloaded?`, redirect to pricing and **return** without incrementing. Only increment after we know we are actually serving a paid/downloaded-user bundle. Regression spec: `does not increment download count when redirecting trial users to pricing`.

**Evidence (after fix):** Same `curl` flow; `download_count` remained `0` after redirect to pricing.

---

### 2.2 Hidden “Confirm sign out” / “Are you sure?” dialogs on public pages

**Symptom:** Accessibility snapshots on `/`, `/pricing`, and `/signup` included headings for logout and generic confirm modals even when not signed in.

**Root cause:** Global modals in `layouts/application.html.erb` were always rendered; they were visually hidden but still exposed to the accessibility tree.

**Fix:** Render those modals only when `logged_in?` so marketing and auth pages stay clean for assistive tech.

---

### 2.3 “Mark as downloaded” HTTP endpoint (payment bypass)

**Symptom:** `POST /app/download/mark` called `mark_as_downloaded!` for any user with an **active trial**, granting `device_downloaded` without going through Polar/checkout.

**Risk:** Anyone who could trigger that request while logged in (e.g. crafted form, dev tools) could unlock “downloaded” status without paying. CSRF reduces cross-site risk but does not remove the issue for a motivated user.

**Fix:** `mark_downloaded` now returns `404` outside `development` and `test`. Staging/production must rely on webhooks / purchase completion to set `device_downloaded`.

---

## 3. Security / “pretend you’re hacking” summary

| Check | Outcome |
|--------|---------|
| `/app/download` without session | Redirect to login |
| `/app/download/app?token=invalid` | Redirect to login (no user) |
| Valid token, trial user | Redirect to pricing; **quota bug fixed** |
| `POST /app/download/mark` in production | **Now 404** (was exploitable) |

**Still worth monitoring:** Download tokens are bearer secrets; anyone with the token can hit download URLs until rotation. Ensure tokens are only sent over HTTPS in production and cleared when appropriate (cleanup job already touches old tokens).

---

## 4. Areas exercised lightly (possible follow-ups)

- **Drag-and-drop:** Not fully automated (browser drag is brittle). Manually verify reorder in week columns and Not Yet lists.
- **Rich notes (images + styled text):** Toolbar is present; full upload path and sanitization deserve a dedicated pass (file size, XSS in HTML notes).
- **7-day cutoff:** Trial end is enforced via `trial_expires_at` and `TrialCleanupJob`. To simulate locally:

  ```bash
  bin/rails runner "u = User.find(<id>); u.update!(trial_expires_at: 1.day.ago)"
  ```

  Then sign in and confirm `ResourceAuthorizable` / dashboard behaviour matches product copy (redirects, messaging).

- **`TrialCleanupJob#cleanup_old_download_tokens`:** The ActiveRecord query looks suspicious (nested `User.where`); worth a code review and a unit test so token cleanup does what you intend.

- **SimpleCov:** Running a single spec file can fail the exit code if coverage minimum is unmet; use full suite or project’s documented test command for CI parity.

---

## 5. Files changed in this pass

- `app/controllers/downloads_controller.rb` — download ordering; `mark_downloaded` gated by environment.
- `app/views/layouts/application.html.erb` — modals only when logged in.
- `spec/controllers/downloads_controller_spec.rb` — example for trial download count.

---

## 6. Suggested regression checklist (before release)

1. Sign up → first visit `/app` → trial flash/start behaviour.
2. Trial user → download link → pricing, **download_count unchanged**.
3. Paid / `device_downloaded` user → ZIP download → count increments, file downloads.
4. Logged out → marketing pages → **no** logout/confirm dialogs in a11y tree.
5. Production-like env → `POST /app/download/mark` → **404**.

---

*End of debug plan.*
