# Stripe to Polar.sh Migration

## Overview

Peponi.to has migrated from Stripe to Polar.sh as the Merchant of Record. Polar handles UK VAT/tax, checkout, and payment processing.

## Implementation Status

- [x] DB migration: `polar_customer_id`, `polar_product_id`, `polar_order_id` on users
- [x] `Polar::ProductManager` service for product creation and checkout
- [x] `PolarController` for checkout, success, cancel
- [x] `Webhooks::PolarController` for `order.paid` fulfillment
- [x] Legacy Stripe code moved to `Legacy::StripeController`
- [x] Views, AnalyticsService, and privacy policy updated

## Keys & Secrets: Step-by-Step Instructions

### 1. POLAR_ACCESS_TOKEN (Organization Access Token)

1. Go to [Polar Dashboard](https://polar.sh/dashboard) and sign in.
2. Select your organization from the sidebar (or create one first).
3. Go to **Settings → General** (or `https://polar.sh/dashboard/YOUR_ORG_SLUG/settings`).
4. Scroll to the **Developers** section.
5. Click **New Token**.
6. Configure:
   - **Scopes**: Enable at least `checkouts:write` and `products:read` (or `products:write` if creating via API).
   - **Expiration**: Set as needed (e.g. no expiry for production).
   - **Name**: e.g. `Peponi.to Production`.
7. Click Create → **copy the token immediately** (it’s only shown once).
8. Save as `POLAR_ACCESS_TOKEN` in `.env` and `.kamal/secrets`.

---

### 2. POLAR_PRODUCT_ID

1. In the Polar dashboard, go to **Products → Catalogue** (or `https://polar.sh/dashboard/YOUR_ORG_SLUG/products`).
2. Click **New Product**.
3. Configure:
   - **Name**: `Peponi.to - Download to Device`
   - **Description**: `Download to your device forever - unlimited pages, offline access, and data ownership`
   - **Billing cycle**: **One-time purchase**
   - **Pricing type**: **Fixed price**
   - **Price**: `£9.99` (or equivalent in your currency)
4. Add other currencies if needed, then save.
5. On the product list, click the **⋮** (three dots) next to the product.
6. Choose **Copy Product ID**.
7. Save as `POLAR_PRODUCT_ID` in `.env` and `.kamal/secrets`.

---

### 3. POLAR_WEBHOOK_SECRET

1. In the Polar dashboard, go to **Settings** → **Webhooks** (or organization settings where webhooks are managed).
2. Click **Add Endpoint**.
3. Enter the endpoint URL:
   ```
   https://peponi.to/webhooks/polar
   ```
   (Use your real domain in production; for local tests use `polar listen`.)
4. **Delivery format**: Keep **Raw** (JSON).
5. **Secret**:
   - Click **Generate** or type your own long random string.
   - Copy the secret right away.
6. **Events**: Subscribe to at least:
   - `order.paid`
   - `order.updated`
   - `order.created`
7. Save the endpoint.
8. Save the secret as `POLAR_WEBHOOK_SECRET` in `.env` and `.kamal/secrets`.

---

### 4. POLAR_ORGANIZATION_ID (optional, for API product creation)

- Visible in the dashboard URL: `https://polar.sh/dashboard/YOUR_ORG_SLUG/...`
- Or in the organization settings page.
- Only needed if you use `bin/rails polar:create_product` instead of creating the product in the UI.

## Setup Checklist

1. **Create Organization & Product on Polar**
   - Sign up at https://polar.sh
   - Create a one-time product: "Peponi.to - Download to Device" at £9.99
   - Or run: `POLAR_ORGANIZATION_ID=your-org-uuid POLAR_ACCESS_TOKEN=xxx bin/rails polar:create_product`

2. **Configure Webhook**
   - Add endpoint: `https://your-domain.com/webhooks/polar`
   - Subscribe to: `order.paid`, `order.updated`, `order.created`
   - Copy the webhook secret to `POLAR_WEBHOOK_SECRET`

3. **Environment Variables**
   ```bash
   POLAR_ACCESS_TOKEN=polar_oat_...
   POLAR_PRODUCT_ID=uuid-from-dashboard
   POLAR_WEBHOOK_SECRET=whsec_...
   ```

4. **Run Migration**
   ```bash
   bin/rails db:migrate
   ```

## File Benefits (Optional)

For Polar-hosted downloadable files (vs. our dynamic PWA ZIP), you would:
- Create a File via `POST /v1/files` (multipart S3 upload)
- Create a Benefit of type `downloadables` linked to that file
- Attach the benefit to the product

Peponi.to uses webhook fulfillment: when `order.paid` fires, we mark the user and send our own download link. No Polar file upload needed.

---

## 100% Test Discount (Gift Code) for Local Testing

To test the full flow (checkout → order.paid webhook → download + email) without charging a card:

### Option A: Create via API (recommended)

1. Ensure your Polar access token has `discounts:write` scope (Organization → Access Tokens → edit token).
2. Create the discount:
   ```bash
   bin/rails polar:create_test_discount
   ```
   (Add `POLAR_ORGANIZATION_ID=your-org-uuid` if your token needs it.)

2. Copy the discount ID and add to `.env`:
   ```
   POLAR_TEST_DISCOUNT_ID=<discount-uuid-from-output>
   ```

3. Restart the server. The Buy button will auto-apply the 100% discount at checkout. Complete checkout (no payment needed) → webhook fires → download + email.

### Option B: Create in Polar dashboard

1. Go to **Products** → **Discounts** (or your org’s discount section).
2. Create a new discount:
   - **Type**: Percentage
   - **Amount**: 100%
   - **Duration**: Once
   - **Code**: `FAMTEST` (or any code)
   - **Name**: Peponi.to Test 100%
3. Copy the discount ID and set `POLAR_TEST_DISCOUNT_ID` in `.env`.
4. Or use the code at checkout: add `?discount_code=FAMTEST` to the checkout URL (requires code support in your flow).

### Flow after checkout

When checkout completes (payment or 100% discount), Polar sends `order.paid`. Our webhook:

1. Finds the user (metadata or email)
2. Marks `device_downloaded`
3. Generates a download token
4. Sends the purchase confirmation email with the download link

**Production:** Remove or leave `POLAR_TEST_DISCOUNT_ID` unset so normal paid checkouts are used.

---

## Manual Frontend Testing

1. **Ensure the app is running:**
   ```bash
   bin/rails server
   ```

2. **Use the test account** (or create your own):
   - Email: `polar-test@example.com`
   - Password: `password123`
   - *(Created via `bin/rails runner` if needed)*

3. **Test the checkout flow:**
   - Go to http://localhost:3000
   - Click **Sign In** → log in with the test account
   - Go to **Pricing** (or **Settings**)
   - Click **"Download to Device"** or **"Buy Download (£9.99)"**
   - You should be redirected to Polar’s checkout (`https://buy.polar.sh/...` or sandbox equivalent)

4. **Optional: complete a test purchase**
   - Use Polar’s sandbox/test cards if in sandbox mode
   - After payment, you should be redirected to `/app/polar/success`
   - The webhook will mark the user and send the confirmation email

5. **Verify webhook delivery** (production/staging):
   - In Polar Dashboard → Webhooks → your endpoint
   - Check delivery logs for `order.paid` events
