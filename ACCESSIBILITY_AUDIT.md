# Todo-it Accessibility Audit

**Date:** February 25, 2025  
**Scope:** Full application (marketing pages, app pages, auth flows, modals)  
**Standards:** WCAG 2.1 Level AA

---

## Executive Summary

| Category      | Critical | Serious | Moderate | Fixed |
|--------------|-----------|---------|----------|-------|
| Skip links   | 1         | 0       | 0        | ✓     |
| Headings     | 2         | 1       | 0        | ✓     |
| Contrast     | 0         | 2       | 1        | —     |
| ARIA/Semantics | 3       | 2       | 0        | ✓     |
| Focus/Keyboard | 2      | 1       | 0        | ✓     |
| Forms        | 1         | 0       | 0        | ✓     |

---

## 1. Skip Links

### ~~Critical: No "Skip to main content" link~~ ✓ FIXED

**WCAG 2.4.1 (Bypass Blocks)**

- Keyboard and screen reader users must tab through the entire navbar before reaching main content.
- **Fix applied:** Skip link added; main content wrapped in `<main id="main-content">`.

---

## 2. Headings

### ~~Critical: Missing h1 on auth pages (Sign In, Create Account)~~ ✓ FIXED

**WCAG 1.3.1 (Info and Relationships)**

- **Fix applied:** Changed h2 to h1 on Sign In and Create Account pages.

### Critical: Heading level skip in email templates

**Example:** `password_changed.html.erb` – h1 → h3 (skips h2).  
**Example:** `email_changed.html.erb` – same pattern.  
Headings should not skip levels (e.g. h1 → h2 → h3).

### ~~Serious: Logout modal uses h5 for title~~ ✓ FIXED

**Location:** `application.html.erb`  
- **Fix applied:** Changed to `<h2>` for clearer heading structure.

---

## 3. Landmarks & Semantics

### ~~Critical: No `<main>` landmark~~ ✓ FIXED

**WCAG 1.3.1, 2.4.1**

- **Fix applied:** Main content wrapped in `<main id="main-content">` (used by skip link).

### ~~Moderate: Nav elements lack aria-label~~ ✓ FIXED

- **Fix applied:** `aria-label="Main navigation"` added to both navbar and marketing header.

---

## 4. ARIA & Live Regions

### ~~Critical: Flash messages not announced~~ ✓ FIXED

**WCAG 4.1.3 (Status Messages)**

- **Fix applied:** `role="alert"`, `aria-live="assertive"` for errors, `aria-live="polite"` for success/notice.

### ~~Serious: Mobile menu missing aria-hidden when closed~~ ✓ FIXED

- **Fix applied:** `aria-hidden` added to mobile menu and toggled with open/close state (navbar + marketing header).

---

## 5. Focus & Keyboard

### ~~Critical: Outline removed on focus~~ ✓ FIXED

**WCAG 2.4.7 (Focus Visible)**

- **Fix applied:** `:focus-visible` with visible outline added for menu buttons, close button, modal buttons, footer links. `focus:outline-none` utility now includes `:focus-visible` override.

### ~~Serious: Logout modal focus management~~ ✓ FIXED

- **Fix applied:** Focus goes to close button when opening; focus returns to trigger element when closing. (Focus trap not yet implemented – Tab can still leave modal; consider adding for full compliance.)

### Moderate: Theme selector buttons lack aria-label

- Theme buttons (Classic, Lined, Graph, etc.) rely on visual styling. Add `aria-label="Select Classic theme"` (etc.) so their purpose is clear without visual context.

---

## 6. Color Contrast

### (Footer fixed in previous session)

Footer colors were updated; no additional critical contrast issues found in footer.

### Serious: Pricing card labels (0.8rem, #64748b)

**Location:** `pricing.html.erb` – "Free Trial", "Download to Device" labels.  
- `font-size: 0.8rem`, `color: #64748b` on white. At small sizes, contrast should be stronger.
- **Recommendation:** Use `0.875rem` and a darker gray (e.g. #475569) for better contrast.

### Moderate: text-gray-500 / text-gray-400

- `.text-gray-500` (#6b7280) and `.text-gray-400` (#9ca3af) on light backgrounds may be borderline for WCAG AA.
- **Audit:** Check combinations where these classes are used; prefer `text-gray-600` or darker for body text.

---

## 7. Forms

### Forms – Verified

- Rails form labels correctly associate with inputs via `for`/`id`.
- **Fix applied:** Registration validation errors div now has `role="alert"` for announcements.

### Moderate: Error messages and validation

- Registration error list could use `role="alert"` so validation errors are announced.

---

## 8. Interactive Elements

### Verified: Good aria-label usage

- FAB navigation: `aria-label` on open/close and nav links.
- Pages index: `aria-label="Edit page: X"`, `aria-label="Delete page: X"`.
- Pages show: `aria-label` on todo checkbox, drag handle, edit/delete.
- Logout modal close: `aria-label="Close"`.
- Mobile menu: `sr-only` text for "Open main menu", "Close menu".

### Improvement: Decorative SVGs

- Decorative SVGs correctly use `aria-hidden="true"`.

---

## 9. Miscellaneous

### Drag handle keyboard support

- Drag handle has `role="button"` and `tabindex="0"` but no keyboard handler (e.g. Space/Enter to activate drag, arrow keys to move).
- **Recommendation:** Add keyboard support or clarify in aria-label that reordering is mouse/touch only for now.

### PWA install button

- Button is `class="hidden"` by default; when shown, it has no `aria-label`. Add `aria-label="Install Todo-it app"` when implementing.

---

## Recommended Fix Order

1. **Skip link** – high impact, low effort.
2. **Main landmark** – wrap content in `<main id="main-content">`; can pair with skip link.
3. **Auth page h1** – change h2 to h1 on Sign In and Create Account.
4. **Flash message `role="alert"`** – ensures announcements.
5. **Focus visible** – replace `outline: none` with visible focus styles.
6. **Mobile menu `aria-hidden`** – improves semantics when menu is closed.

---

## Testing Tools

- **axe DevTools** (browser extension)
- **Lighthouse** (Chrome) – Accessibility audit
- **Keyboard:** Tab through entire app; ensure focus order and visibility
- **Screen reader:** VoiceOver (macOS/iOS), NVDA (Windows)
