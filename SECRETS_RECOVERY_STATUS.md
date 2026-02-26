# Secrets Recovery Status

**Last updated:** Recovery from hard drive loss – secrets extracted from Droplet.

## Completed

- [x] Added `STRIPE_WEBHOOK_SECRET` to [config/deploy.yml](config/deploy.yml)
- [x] Created [.kamal/secrets](.kamal/secrets) with extracted values
- [x] Extracted from Droplet: `RAILS_MASTER_KEY`, `STRIPE_SECRET_KEY`, `STRIPE_PUBLISHABLE_KEY`
- [x] Docker is installed locally

## You Still Need To Do

### 1. Add Docker Hub token (required for deploy)

**Prerequisite (Mac):** Make sure [Docker Desktop](https://www.docker.com/products/docker-desktop/) is running – check the whale icon in the menu bar. Kamal builds images locally and needs the Docker daemon.

1. Go to [Docker Hub](https://hub.docker.com) and log in
2. Click your profile icon → **Account Settings** → **Security**
3. Click **New Access Token**
4. Set **Access permissions** to Read, Write, Delete (Kamal pushes images)
5. Give it a name (e.g. `kamal-todo-app`) and click **Generate**
6. **Copy the token immediately** – Docker Hub only shows it once
7. Add to `.kamal/secrets` (line 2, replace the empty value):
   ```
   KAMAL_REGISTRY_PASSWORD=dckr_pat_xxxxxxxxxxxx
   ```
   **Important:** Save the file (Cmd+S). Kamal reads from disk – unsaved changes won't work.

### 2. Add Stripe webhook secret (required for webhooks)

`STRIPE_WEBHOOK_SECRET` was not set on the Droplet. To enable Stripe webhooks:

1. [Stripe Dashboard](https://dashboard.stripe.com) → Developers → Webhooks
2. Add endpoint: `https://todo-it.app/stripe/webhook`
3. Copy the **Signing secret** (`whsec_...`) and add to `.kamal/secrets`:
   ```
   STRIPE_WEBHOOK_SECRET=whsec_...
   ```

### 3. Add contact form email (for Contact page)

**DigitalOcean blocks outbound SMTP**, so we use Brevo's API (HTTPS) instead.

1. Sign up at [Brevo](https://www.brevo.com) (free: 300 emails/day)
2. **SMTP & API** → **API Keys** → Create key → copy it
3. **Senders & IP** → Add and verify your sender email (e.g. `elefsinian@gmail.com`)
4. Add to `.kamal/secrets`:
   ```
   CONTACT_EMAIL=elefsinian@gmail.com
   BREVO_API_KEY=xkeysib-xxxxxxxxxxxx
   ```

### 4. Deploy

Ensure Docker Desktop is running (whale icon in menu bar), then:

```bash
bin/kamal deploy
```

## Note on Stripe Keys

The extracted keys show `STRIPE_PUBLISHABLE_KEY` as test (`pk_test_...`) and `STRIPE_SECRET_KEY` as live (`sk_live_...`). If you see payment issues, consider aligning them (both test or both live) in the [Stripe Dashboard](https://dashboard.stripe.com/apikeys).
