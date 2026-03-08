# Next Focus Plan – Today's Tasks

This document outlines the details and requirements for the four items planned for today.

---

## 3. Hot-Reload Bug Fix

### Current State
- **Procfile.dev:** Only runs `web: bin/rails server`.
- **Asset pipeline:** Propshaft (Rails default).
- **JavaScript:** Importmap + Turbo + Stimulus.
- **No explicit hot-reload setup:** No Guard, Listen, or livereload gems.

### Likely "Hot-Reload Bug"
- CSS or view changes require a manual browser refresh to appear.
- Possible causes:
  1. No file watcher for CSS/ERB.
  2. Turbo Drive caching pages.
  3. Propshaft/asset fingerprinting cache.
  4. Service worker caching (PWA).

### Requirements
1. **Identify** the specific symptom (e.g. CSS, JS, or ERB not updating without refresh).
2. **Fix** so that code changes are reflected without manual reload.

### Implementation Options

| Approach | Pros | Cons |
|---------|------|------|
| **Turbo morph / refresh** | Uses existing stack | May need explicit refresh triggers |
| **Add `bin/dev` watcher** | Standard Rails pattern | Requires extra process |
| **LiveReload / guard-livereload** | Full reload on change | Adds gems and setup |
| **Rails 8 default `bin/dev`** | Simple if supported | Check current Rails 8 defaults |

### Files to Inspect
- `Procfile.dev` – what runs in dev.
- `config/environments/development.rb` – asset and cache settings.
- Turbo Drive settings (e.g. `data-turbo-permanent`).
- Service worker (`app/views/pwa/service-worker.js`) – may cache assets.

### Recommended Next Steps
1. Reproduce the bug (describe when changes don’t appear).
2. Check if `stylesheet_link_tag` uses `data-turbo-track="reload"` (it does in `application.html.erb`).
3. Consider adding a CSS watcher to `Procfile.dev` (e.g. via `listen` or `cssbundling-rails` if adopted).
4. Verify development mode disables aggressive caching.

---

## 4. Stripe to Paddle Migration

### Current Stripe Integration
- **Controller:** `app/controllers/stripe_controller.rb`
  - `create_checkout_session` – creates Stripe Checkout Session, redirects to Stripe-hosted page
  - `success` – retrieves session, verifies ownership, calls `mark_as_downloaded!`, sends email, redirects to download
  - `cancel` – redirects to settings with notice
  - `customer_portal` – placeholder (redirects to pricing)
  - `webhook` – handles `checkout.session.completed`, `payment_intent.succeeded`; verifies signature via `STRIPE_WEBHOOK_SECRET`
- **Config:** `config/initializers/stripe.rb` – sets `Stripe.api_key` from `ENV["STRIPE_SECRET_KEY"]`
- **Gem:** `stripe` (~18.3.1) in Gemfile
- **Routes:** `config/routes.rb` lines 70–74
  - `POST /app/stripe/create-checkout-session` → `create_checkout_session`
  - `GET /app/stripe/success` → `success`
  - `GET /app/stripe/cancel` → `cancel`
  - `GET /app/stripe/customer-portal` → `customer_portal`
  - `POST /app/stripe/webhook` → `webhook`

### Product & Payment Flow
- **Product:** One-time payment, £9.99 (stored as 990 cents USD in code)
- **Flow:** User clicks Buy → Stripe Checkout redirect → success callback → `User#mark_as_downloaded!` + download token + confirmation email
- **Webhook:** Backup confirmation; also calls `mark_as_downloaded!`, analytics, and email

### References to Stripe
- `app/views/marketing/pricing.html.erb` – CTA uses `create_checkout_session_path`; copy says "Secure payment via Stripe"
- `app/views/settings/index.html.erb` – upgrade buttons use `create_checkout_session_path`
- `app/views/marketing/privacy.html.erb` – mentions Stripe for payment processing
- `app/services/analytics_service.rb` – `track_payment_completion` stores `stripe_session_id`
- `spec/controllers/stripe_controller_spec.rb` – full controller specs

### Paddle Migration Requirements
1. **Replace Stripe gem** with Paddle SDK / HTTP integration (Paddle uses REST API; no official Ruby gem; consider `paddle-ruby` or direct HTTP).
2. **New controller (e.g. `PaddleController`)** or refactor to a payment-agnostic controller:
   - Create Checkout: Paddle uses overlay or redirect checkout; configure product/price in Paddle dashboard.
   - Success: Paddle uses webhooks as primary; optional success URL for redirect.
   - Webhooks: Paddle events differ (e.g. `subscription_created`, `transaction_completed`); verify signature with Paddle public key.
3. **Environment variables:**
   - Replace `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` with Paddle equivalents (e.g. `PADDLE_VENDOR_ID`, `PADDLE_AUTH_CODE`, `PADDLE_PUBLIC_KEY` for webhook verification).
4. **Update routes** – point to new Paddle endpoints (keep similar paths for clarity, e.g. `/app/paddle/...`).
5. **Update views** – replace `create_checkout_session_path` with Paddle checkout URL or overlay trigger.
6. **Update AnalyticsService** – store Paddle transaction/subscription ID instead of `stripe_session_id`.
7. **Update privacy policy** – replace Stripe with Paddle.
8. **Migrate existing purchasers** – ensure `device_downloaded?` users are unaffected; no re-purchase required.
9. **Tests** – port or rewrite `stripe_controller_spec.rb` for Paddle flows.

### Paddle-Specific Notes
- Paddle is merchant of record (handles tax, VAT, invoicing).
- Checkout can be overlay (JS) or redirect; overlay often requires Paddle.js script.
- Webhook payload structure and signing differ from Stripe; see Paddle docs for verification.
- Pricing: configure product/price in Paddle dashboard; currency can be multi-currency.

---

## Summary

| Item | Main File(s) | Estimated Effort |
|------|--------------|------------------|
| Dotted background brighter | `app/assets/stylesheets/application.css` | ~15 min |
| Calendar view | `DashboardController`, `dashboard/index`, routes | 2–4 hours |
| Hot-reload fix | Procfile.dev, Turbo/Propshaft config | ~30 min – 1 hour |
| Stripe → Paddle migration | `StripeController`, routes, views, AnalyticsService, privacy | 4–8 hours |

---

*Created: 2025-03-08*
