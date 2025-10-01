# Todo-it App Test Plan

## Version 3.0 - 7-Day Trial + Device Download

### Test Environment Setup

- **Rails Server**: `rails server` running on localhost:3000
- **Database**: SQLite (development)
- **Browser**: Chrome/Safari with DevTools open
- **Test User**: Create a new user account for testing

---

## 1. User Registration & Trial Flow

### 1.1 New User Registration

- [ ] **Test**: Visit `/` (landing page)
- [ ] **Test**: Click "Start Free Trial" button
- [ ] **Test**: Fill out registration form with valid email
- [ ] **Test**: Submit registration
- [ ] **Expected**: User redirected to `/app` with trial status message
- [ ] **Expected**: Trial started at current time, expires in 7 days
- [ ] **Expected**: User can create pages and todos immediately

### 1.2 Trial Status Display

- [ ] **Test**: Check trial status on `/app` page
- [ ] **Expected**: Shows "Free Trial: X days remaining • Unlimited pages during trial"
- [ ] **Test**: Check trial status on `/app/settings` page
- [ ] **Expected**: Same trial status message displayed
- [ ] **Test**: Check trial status on todo pages (e.g., `/app/pages/1`)
- [ ] **Expected**: NO trial status message (clean interface)

---

## 2. Data Export & Import System

### 2.1 JSON Export

- [ ] **Test**: Create some test data (pages and todos)
- [ ] **Test**: Go to `/app/trial/status`
- [ ] **Test**: Click "Export My Data" button
- [ ] **Expected**: Browser downloads JSON file
- [ ] **Expected**: JSON contains user data, pages, and todos
- [ ] **Expected**: File named like `todo-it-data-{user_id}-{timestamp}.json`

### 2.2 Data Validation

- [ ] **Test**: Open downloaded JSON file
- [ ] **Expected**: Contains metadata (version, exported_at, app_name)
- [ ] **Expected**: Contains user_info (id, name, email_domain, trial dates)
- [ ] **Expected**: Contains pages array with todos
- [ ] **Expected**: All data properly formatted and complete

---

## 3. Payment & Download Flow

### 3.1 Payment Process

- [ ] **Test**: Go to `/app/trial/status`
- [ ] **Test**: Click "Download App" button
- [ ] **Expected**: Redirected to `/pricing` with flash message
- [ ] **Test**: Click "Download to Device - $9.99" button
- [ ] **Expected**: Redirected to Stripe checkout
- [ ] **Test**: Complete payment (use test card: 4242 4242 4242 4242)
- [ ] **Expected**: Redirected to download page with success message

### 3.2 ZIP Download

- [ ] **Test**: After successful payment, click download link
- [ ] **Expected**: Browser downloads ZIP file
- [ ] **Expected**: ZIP contains: index.html, manifest.json, service-worker.js, styles.css, README.txt, user-data.json
- [ ] **Expected**: File named like `todo-it-app-{user_id}-{timestamp}.zip`

### 3.3 PWA Bundle Contents

- [ ] **Test**: Extract ZIP file
- [ ] **Test**: Open index.html in browser
- [ ] **Expected**: Shows offline app page with installation instructions
- [ ] **Expected**: Service worker registers successfully
- [ ] **Expected**: User data is included in the bundle

---

## 4. Navigation & UI Components

### 4.1 Desktop Navigation

- [ ] **Test**: Check desktop navbar on all pages
- [ ] **Expected**: Shows user name, settings link, logout link
- [ ] **Test**: Click "Settings" link
- [ ] **Expected**: Navigates to `/app/settings`
- [ ] **Test**: Click "Logout" link
- [ ] **Expected**: Shows logout confirmation modal

### 4.2 Mobile Navigation (FAB)

- [ ] **Test**: Open app on mobile device or mobile view
- [ ] **Test**: Tap floating action button (bottom right)
- [ ] **Expected**: Bottom sheet slides up with navigation options
- [ ] **Test**: Tap "Pages" option
- [ ] **Expected**: Navigates to pages index
- [ ] **Test**: Tap "Settings" option
- [ ] **Expected**: Navigates to settings page
- [ ] **Test**: Tap "Logout" option
- [ ] **Expected**: Shows logout confirmation modal

### 4.3 Logout Modal

- [ ] **Test**: Click any logout button
- [ ] **Expected**: Beautiful modal appears with smooth animation
- [ ] **Test**: Click "Cancel" button
- [ ] **Expected**: Modal closes, stays logged in
- [ ] **Test**: Click "Logout" button
- [ ] **Expected**: User logged out, redirected to login page
- [ ] **Test**: Press Escape key
- [ ] **Expected**: Modal closes
- [ ] **Test**: Click outside modal
- [ ] **Expected**: Modal closes

---

## 5. Trial Management

### 5.1 Trial Expiration (Simulate)

- [ ] **Test**: Manually set trial_expires_at to past date in database
- [ ] **Test**: Refresh `/app` page
- [ ] **Expected**: Shows "Trial Expired • Download app to continue"
- [ ] **Test**: Try to create new page
- [ ] **Expected**: Redirected to pricing page with error message

### 5.2 Trial Data Cleanup

- [ ] **Test**: Create test user with expired trial
- [ ] **Test**: Run cleanup job (if implemented)
- [ ] **Expected**: Old trial data cleaned up appropriately

---

## 6. PWA Features

### 6.1 Service Worker

- [ ] **Test**: Check browser DevTools > Application > Service Workers
- [ ] **Expected**: Service worker registered and active
- [ ] **Test**: Go offline (DevTools > Network > Offline)
- [ ] **Expected**: App shows offline indicator
- [ ] **Test**: Go back online
- [ ] **Expected**: Offline indicator disappears

### 6.2 PWA Installation

- [ ] **Test**: Check for install prompt in browser
- [ ] **Expected**: "Install Todo-it" button appears (if supported)
- [ ] **Test**: Install app
- [ ] **Expected**: App installs as standalone PWA
- [ ] **Expected**: App works offline after installation

---

## 7. Error Handling & Edge Cases

### 7.1 Invalid Download Token

- [ ] **Test**: Manually modify download URL with invalid token
- [ ] **Expected**: Shows error message, redirected to app root

### 7.2 Export Without Data

- [ ] **Test**: Create user with no pages/todos
- [ ] **Test**: Try to export data
- [ ] **Expected**: Export still works, creates empty JSON

### 7.3 Payment Failure

- [ ] **Test**: Use invalid card number in Stripe
- [ ] **Expected**: Shows error message, stays on pricing page

---

## 8. Accessibility & Performance

### 8.1 Keyboard Navigation

- [ ] **Test**: Navigate entire app using only keyboard
- [ ] **Expected**: All interactive elements accessible via Tab/Enter
- [ ] **Test**: Use Escape key to close modals
- [ ] **Expected**: Modals close properly

### 8.2 Screen Reader Support

- [ ] **Test**: Use screen reader to navigate app
- [ ] **Expected**: All content properly announced
- [ ] **Expected**: Modal has proper ARIA labels

### 8.3 Mobile Performance

- [ ] **Test**: Test on actual mobile device
- [ ] **Expected**: Smooth animations, responsive design
- [ ] **Expected**: Touch gestures work properly

---

## 9. Data Integrity

### 9.1 Export/Import Round Trip

- [ ] **Test**: Export user data
- [ ] **Test**: Create new user account
- [ ] **Test**: Import data into new account
- [ ] **Expected**: All data imported correctly
- [ ] **Expected**: No data loss or corruption

### 9.2 Concurrent Users

- [ ] **Test**: Multiple users using app simultaneously
- [ ] **Expected**: No data conflicts or issues

---

## 10. Security & Privacy

### 10.1 Data Protection

- [ ] **Test**: Check exported JSON doesn't contain sensitive data
- [ ] **Expected**: Only email domain, not full email address
- [ ] **Expected**: No passwords or tokens in export

### 10.2 Access Control

- [ ] **Test**: Try to access other users' data
- [ ] **Expected**: Proper authorization checks prevent access

---

## Test Results Summary

### Pass/Fail Tracking

- [ ] **Total Tests**: 50+
- [ ] **Passed**: \_\_\_
- [ ] **Failed**: \_\_\_
- [ ] **Critical Issues**: \_\_\_
- [ ] **Minor Issues**: \_\_\_

### Notes

- **Test Date**: \***\*\_\_\_\*\***
- **Tester**: \***\*\_\_\_\*\***
- **Browser**: \***\*\_\_\_\*\***
- **Device**: \***\*\_\_\_\*\***
- **Rails Version**: \***\*\_\_\_\*\***

---

## Post-Test Actions

### If All Tests Pass

- [ ] Deploy to staging environment
- [ ] Run integration tests
- [ ] Prepare for production deployment

### If Tests Fail

- [ ] Document specific failures
- [ ] Fix critical issues first
- [ ] Re-run failed tests
- [ ] Update test plan if needed

---

_This test plan ensures the Todo-it app works correctly across all user flows, from registration through trial to payment and download. Each test should be checked off as completed._
