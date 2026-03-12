# Domain Migration: peponi.to + Droplet Rename

Step-by-step guide to point peponi.to to your DigitalOcean droplet and rename the droplet.

**Current setup:**
- Droplet IP: `161.35.185.189`
- New domain: `peponi.to`
- Old domain: `todo-it.app` (or similar)

---

## Part 1: Namecheap — Point peponi.to to Your Droplet

### Step 1.1: Log in to Namecheap

1. Go to [namecheap.com](https://www.namecheap.com) and sign in
2. Click **Domain List** in the left sidebar
3. Find **peponi.to** (or add/register it if you haven’t yet)

### Step 1.2: Open DNS Settings

1. Click **Manage** next to peponi.to
2. Open the **Advanced DNS** tab

### Step 1.3: Add or Update A Records

You need these records:

| Type | Host | Value | TTL |
|------|------|-------|-----|
| A Record | @ | 161.35.185.189 | Automatic |
| A Record | www | 161.35.185.189 | Automatic |

**Steps:**

1. Click **Add New Record**
2. Choose **A Record**
3. Host: `@` (for peponi.to root)
4. Value: `161.35.185.189`
5. TTL: **Automatic** or **1 min** for testing, then switch to **Automatic**
6. Save

7. Add another A Record:
   - Host: `www` (for www.peponi.to)
   - Value: `161.35.185.189`
   - TTL: Automatic
   - Save

### Step 1.4: Optional — WWW Redirect (recommended)

To redirect www.peponi.to → peponi.to:

1. Add **URL Redirect Record**
2. Host: `www`
3. Value: `https://peponi.to`
4. Redirect type: **Permanent (301)**
5. Save

### Step 1.5: Remove Old Records (if migrating from todo-it.app)

If peponi.to used to point elsewhere, or you’re moving from another domain:

- Remove A records that pointed to other IPs
- Remove CNAME records that pointed to the old app

### Step 1.6: Verify Nameservers

- Keep **Namecheap BasicDNS** (or your current DNS) unless you use Custom DNS
- If you use Cloudflare or another DNS provider, add the A records there instead

---

## Part 2: Propagation Check (5–30 minutes)

DNS can take from a few minutes to 48 hours to propagate.

**Quick check:**

```bash
# From your terminal:
dig peponi.to +short
# Should return: 161.35.185.189

dig www.peponi.to +short
# Should return: 161.35.185.189
```

Or use [whatsmydns.net](https://www.whatsmydns.net) and search for `peponi.to`.

---

## Part 3: DigitalOcean — Rename the Droplet

### Step 3.1: Log in to DigitalOcean

1. Go to [cloud.digitalocean.com](https://cloud.digitalocean.com)
2. Sign in to your account

### Step 3.2: Open the Droplet

1. Click **Droplets** in the left sidebar
2. Find the droplet with IP `161.35.185.189`
3. Click its name to open it

### Step 3.3: Rename

1. Click the current name at the top (or the **…** menu)
2. Select **Rename** (or click the pencil icon next to the name)
3. Enter the new name, for example:
   - `peponi-to-prod`
   - `peponi-to-web`
   - `peponi-to-app`
4. Confirm

The droplet hostname changes; the IP (`161.35.185.189`) stays the same.

---

## Part 4: Kamal / Let’s Encrypt (after DNS propagates)

Once `peponi.to` resolves to your droplet:

1. **Redeploy** to trigger SSL certificate for peponi.to:

   ```bash
   kamal deploy
   ```

2. Kamal/Traefik will request a Let’s Encrypt certificate for peponi.to.

3. **Check the app:**

   ```bash
   curl -I https://peponi.to/up
   ```

   You should see `200 OK`.

---

## Part 5: Optional — Old Domain Redirect

If you still get traffic to `todo-it.app` and want to redirect it to peponi.to:

1. In Kamal, you can add multiple hosts (see Kamal docs for `proxy.host`)
2. Or set up a redirect at the DNS level (e.g. redirect service at your registrar)
3. Or add a second Kamal destination with `host: todo-it.app` that redirects to peponi.to (requires extra config)

---

## Checklist

- [ ] Namecheap: A record for `@` → 161.35.185.189
- [ ] Namecheap: A record for `www` → 161.35.185.189
- [ ] (Optional) Namecheap: 301 redirect www → root
- [ ] Wait for DNS propagation (`dig peponi.to +short` returns 161.35.185.189)
- [ ] DigitalOcean: Droplet renamed
- [ ] Run `kamal deploy` to issue SSL for peponi.to
- [ ] Test https://peponi.to in a browser

---

## Troubleshooting

| Problem | What to check |
|---------|----------------|
| `peponi.to` doesn’t resolve | DNS propagation; wait 5–30 min and check `dig peponi.to +short` |
| SSL error / no certificate | Ensure DNS is correct, then run `kamal deploy` |
| 502 Bad Gateway | App may be down; run `kamal app logs -f` |
| Old domain still used | Either add it back in Kamal or set up a redirect elsewhere |
