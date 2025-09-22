# Implementation Plan: 30-Day Trial + Device Download Model

## Overview

Transform Todo-it from a traditional SaaS model to a hybrid approach:

- **30-day free trial** hosted on our servers
- **One-time payment** to download the app to user's device
- **Offline-first** experience after download

---

## Phase 1: Backend Architecture Changes (2-3 weeks)

### 1.1 User Trial Management

**Priority: High | Effort: Medium**

#### Database Changes

- [ ] Add `trial_started_at` timestamp to users table
- [ ] Add `trial_expires_at` timestamp to users table
- [ ] Add `device_downloaded` boolean to users table
- [ ] Add `download_token` string to users table (for secure downloads)
- [ ] Add `trial_data_exported` boolean to users table

#### Controller Updates

- [ ] Update `RegistrationsController` to set trial dates
- [ ] Add trial expiration checks to `ApplicationController`
- [ ] Create `TrialController` for trial management
- [ ] Add trial status checks to all app controllers

#### Model Updates

- [ ] Add trial validation methods to `User` model
- [ ] Add trial expiration scopes
- [ ] Add data export methods

### 1.2 Trial Data Management

**Priority: High | Effort: Medium**

#### Data Export System

- [ ] Create `DataExportService` for trial data
- [ ] Add JSON export format for pages and todos
- [ ] Add data import functionality for device app
- [ ] Create trial data cleanup job (runs daily)

#### Trial Limits

- [ ] Implement trial feature restrictions
- [ ] Add trial expiration warnings (7 days, 3 days, 1 day)
- [ ] Create trial extension system (if needed)

---

## Phase 2: PWA Download System (3-4 weeks)

### 2.1 PWA Enhancement

**Priority: High | Effort: High**

#### Service Worker Updates

- [ ] Create offline-first service worker
- [ ] Implement data caching strategies
- [ ] Add background sync for trial data
- [ ] Create update notification system

#### App Manifest

- [ ] Update PWA manifest for device installation
- [ ] Add app icons for all device sizes
- [ ] Configure install prompts
- [ ] Add app shortcuts

#### Offline Functionality

- [ ] Implement IndexedDB for local storage
- [ ] Create offline data sync
- [ ] Add conflict resolution
- [ ] Build offline indicators

### 2.2 Download System

**Priority: High | Effort: Medium**

#### Download Controller

- [ ] Create `DownloadsController` for app downloads
- [ ] Implement secure download token system
- [ ] Add download tracking and analytics
- [ ] Create download success/failure handling

#### App Bundle Creation

- [ ] Create app bundling system
- [ ] Implement version management
- [ ] Add device-specific optimizations
- [ ] Create update mechanism

---

## Phase 3: Payment Integration (1-2 weeks)

### 3.1 Stripe Integration Updates

**Priority: High | Effort: Low**

#### Payment Flow

- [ ] Update Stripe checkout for "Download to Device"
- [ ] Modify success page to provide download link
- [ ] Add download token generation on payment success
- [ ] Update webhook handling for new model

#### User Experience

- [ ] Create payment-to-download flow
- [ ] Add download instructions
- [ ] Implement download tracking
- [ ] Add support for download issues

---

## Phase 4: Frontend Updates (1-2 weeks)

### 4.1 Trial Experience

**Priority: High | Effort: Medium**

#### Trial Indicators

- [ ] Add trial status banner to app
- [ ] Create trial countdown timer
- [ ] Add trial expiration warnings
- [ ] Implement trial upgrade prompts

#### Download Flow

- [ ] Create download preparation page
- [ ] Add download progress indicators
- [ ] Implement download success page
- [ ] Add device installation instructions

### 4.2 Offline App Experience

**Priority: High | Effort: High**

#### Offline UI

- [ ] Create offline indicators
- [ ] Add sync status displays
- [ ] Implement conflict resolution UI
- [ ] Add data management tools

#### Device Features

- [ ] Add device-specific settings
- [ ] Implement local data management
- [ ] Create backup/restore functionality
- [ ] Add data export options

---

## Phase 5: Data Migration & Cleanup (1 week)

### 5.1 Existing User Migration

**Priority: Medium | Effort: Low**

#### Migration Strategy

- [ ] Create migration script for existing users
- [ ] Set appropriate trial dates for current users
- [ ] Add migration notifications
- [ ] Create rollback plan

### 5.2 Trial Data Cleanup

**Priority: Medium | Effort: Low**

#### Cleanup Jobs

- [ ] Create daily trial data cleanup job
- [ ] Implement data retention policies
- [ ] Add cleanup monitoring
- [ ] Create data recovery procedures

---

## Phase 6: Testing & Quality Assurance (1-2 weeks)

### 6.1 Trial Flow Testing

**Priority: High | Effort: Medium**

#### Test Scenarios

- [ ] Test complete trial-to-download flow
- [ ] Test trial expiration handling
- [ ] Test data export/import
- [ ] Test offline functionality

#### Edge Cases

- [ ] Test trial extension scenarios
- [ ] Test download failures
- [ ] Test data corruption recovery
- [ ] Test multiple device downloads

### 6.2 Performance Testing

**Priority: Medium | Effort: Low**

#### Performance Metrics

- [ ] Test app download times
- [ ] Test offline app performance
- [ ] Test data sync performance
- [ ] Test memory usage

---

## Phase 7: Launch & Monitoring (1 week)

### 7.1 Launch Preparation

**Priority: High | Effort: Low**

#### Launch Activities

- [ ] Update all marketing materials
- [ ] Create user migration communications
- [ ] Set up monitoring and analytics
- [ ] Prepare support documentation

#### Monitoring

- [ ] Set up trial conversion tracking
- [ ] Monitor download success rates
- [ ] Track offline app usage
- [ ] Monitor support requests

---

## Technical Considerations

### Database Schema Changes

```sql
-- Add trial management columns
ALTER TABLE users ADD COLUMN trial_started_at TIMESTAMP;
ALTER TABLE users ADD COLUMN trial_expires_at TIMESTAMP;
ALTER TABLE users ADD COLUMN device_downloaded BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN download_token VARCHAR(255);
ALTER TABLE users ADD COLUMN trial_data_exported BOOLEAN DEFAULT FALSE;

-- Add indexes for performance
CREATE INDEX idx_users_trial_expires ON users(trial_expires_at);
CREATE INDEX idx_users_download_token ON users(download_token);
```

### New Models

```ruby
# Trial management
class TrialManager
  def initialize(user)
    @user = user
  end

  def start_trial
    # Set trial dates
  end

  def expired?
    # Check if trial expired
  end

  def export_data
    # Export user data for download
  end
end

# Data export
class DataExportService
  def self.export_user_data(user)
    # Export pages and todos as JSON
  end
end
```

### New Controllers

```ruby
# Trial management
class TrialController < ApplicationController
  def status
    # Show trial status
  end

  def extend
    # Handle trial extensions
  end
end

# Download management
class DownloadsController < ApplicationController
  def prepare
    # Prepare app for download
  end

  def download
    # Serve app bundle
  end
end
```

---

## Success Metrics

### Trial Metrics

- [ ] Trial signup rate
- [ ] Trial completion rate (30 days)
- [ ] Trial-to-download conversion rate
- [ ] Trial user engagement

### Download Metrics

- [ ] Download success rate
- [ ] Device installation rate
- [ ] Offline app usage
- [ ] User satisfaction scores

### Business Metrics

- [ ] Revenue per user
- [ ] Customer lifetime value
- [ ] Support ticket volume
- [ ] User retention rates

---

## Risk Mitigation

### Technical Risks

- [ ] **Data Loss**: Implement robust backup systems
- [ ] **Download Failures**: Create retry mechanisms
- [ ] **Offline Sync Issues**: Build conflict resolution
- [ ] **Performance**: Optimize app bundle size

### Business Risks

- [ ] **User Confusion**: Create clear documentation
- [ ] **Low Conversion**: A/B test trial experience
- [ ] **Support Load**: Build comprehensive help system
- [ ] **Competition**: Monitor market response

---

## Timeline Summary

- **Phase 1**: 2-3 weeks (Backend Architecture)
- **Phase 2**: 3-4 weeks (PWA Download System)
- **Phase 3**: 1-2 weeks (Payment Integration)
- **Phase 4**: 1-2 weeks (Frontend Updates)
- **Phase 5**: 1 week (Data Migration)
- **Phase 6**: 1-2 weeks (Testing & QA)
- **Phase 7**: 1 week (Launch & Monitoring)

**Total Estimated Time**: 10-15 weeks (2.5-3.5 months)

---

## Next Steps

1. **Review and approve this plan**
2. **Set up development environment for PWA testing**
3. **Begin Phase 1: Backend Architecture Changes**
4. **Create detailed technical specifications for each phase**
5. **Set up project management and tracking system**

This implementation plan provides a comprehensive roadmap for transitioning Todo-it to the new 30-day trial + device download model while maintaining a smooth user experience and ensuring data integrity.
