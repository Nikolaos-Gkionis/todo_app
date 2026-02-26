# Next Tasks List

## Contact Form – Brevo Setup (done)

The app is configured for **Brevo** (300 emails/day free, HTTP API, works on DigitalOcean).

### 1. Install the gem

```bash
bundle install
```

### 2. Create a Brevo account

1. Sign up at [brevo.com](https://www.brevo.com)
2. **SMTP & API** → **API Keys** → Create key → copy it (starts with `xkeysib-`)
3. **Senders & IP** → Add and verify your sender email (e.g. `elefsinian@gmail.com`)

### 3. Add to `.kamal/secrets`

```
BREVO_API_KEY=xkeysib-xxxxxxxxxxxx
```

(Save the file – Cmd+S)

### 4. Deploy and test

```bash
git add .
git commit -m "Contact form email via Brevo"
bin/kamal deploy
```

Test at https://todo-it.app/contact
