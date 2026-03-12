# Peponi.to Rebrand

## Brand Overview

- **Brand name:** Peponi.to
- **URL:** peponi.to
- **Origin:** Peponi means "melon" in Greek. The name was chosen for its sound — intentionally irrelevant to the product.
- **Logo:** `peponito.png` — a friendly melon character with transparent background, located at `app/assets/images/peponito.png`

## Environment Variables (Production)

Set these when deploying to peponi.to:

- `SMTP_DOMAIN` = peponi.to
- `MAILER_HOST` = peponi.to
- `CONTACT_EMAIL` = support@peponi.to (or leave unset to use default)

## Email Addresses (only these two)

- **noreply@peponi.to** — System emails (welcome, password changed, trial reminders, etc.)
- **support@peponi.to** — Contact form, privacy, legal, feedback inquiries (all consolidated)

## Checklist of Changed Files

### Shared Partials & Layout
- [x] app/views/shared/_navbar.html.erb
- [x] app/views/shared/_marketing_header.html.erb
- [x] app/views/shared/_footer.html.erb
- [x] app/views/shared/_fab_navigation.html.erb
- [x] app/views/layouts/application.html.erb

### PWA & Icons
- [x] lib/tasks/icons.rake
- [x] app/views/pwa/manifest.json.erb
- [x] app/views/pwa/service-worker.js
- [x] app/controllers/pwa_controller.rb

### Config & Mailers
- [x] config/environments/production.rb
- [x] config/deploy.yml
- [x] app/mailers/application_mailer.rb
- [x] app/mailers/user_mailer.rb
- [x] app/mailers/contact_mailer.rb

### Controllers & Services
- [x] app/controllers/downloads_controller.rb
- [x] app/controllers/trial_controller.rb
- [x] app/controllers/application_controller.rb
- [x] app/controllers/concerns/flash_messageable.rb
- [x] app/controllers/polar_controller.rb
- [x] app/controllers/legacy/stripe_controller.rb
- [x] app/services/data_export_service.rb

### Views (Marketing, Settings, etc.)
- [x] app/views/marketing/landing.html.erb
- [x] app/views/marketing/why.html.erb
- [x] app/views/marketing/how_to.html.erb
- [x] app/views/marketing/pricing.html.erb
- [x] app/views/marketing/privacy.html.erb
- [x] app/views/marketing/terms.html.erb
- [x] app/views/settings/index.html.erb
- [x] app/views/trial/status.html.erb
- [x] app/views/downloads/show.html.erb
- [x] app/views/install/show.html.erb
- [x] app/views/pages/offline.html.erb
- [x] app/views/purchase/complete.html.erb
- [x] app/views/contact_mailer/contact_form.html.erb
- [x] app/views/contact_mailer/contact_form.text.erb
- [x] app/views/user_mailer/*.erb (all)

### Database
- [x] db/migrate/20260312000000_change_app_title_default_to_peponito.rb

### Specs & Docs
- [x] spec/controllers/downloads_controller_spec.rb
- [x] spec/integration/trial_and_download_flow_spec.rb
- [x] README.md
- [x] docs/payment-migration.md

### Rake Tasks
- [x] lib/tasks/email_test.rake
- [x] lib/tasks/email_preview.rake
- [x] lib/tasks/email_debug.rake
- [x] lib/tasks/email_test_fixed.rake
- [x] lib/tasks/polar.rake

## Post-Rebrand Steps (run locally)

1. **Run migration:** `rails db:migrate` (or `bundle exec rails db:migrate`)
2. **Regenerate icons:** `rails icons:generate` (creates PWA icons, favicon from peponito.png)
3. **Verify tests:** `bundle exec rspec`
