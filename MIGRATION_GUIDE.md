# User Migration Guide

## Overview

This guide explains how to migrate existing users from the old premium model to the new 30-day trial + download model.

## Migration Strategy

### For Premium Users

- **Action**: Grandfathered access - immediately marked as "downloaded app"
- **Trial Dates**: Set to account creation date + 30 days (for tracking purposes)
- **Access**: Full access to all features immediately
- **Rationale**: Reward existing paying customers

### For Free Users

- **Action**: Start 30-day trial from migration date
- **Trial Dates**: Set to migration date + 30 days
- **Access**: Full trial access for 30 days
- **Rationale**: Give them a chance to experience the full app

## Migration Commands

### 1. Check Current Status

```bash
bin/rails migration:stats
```

### 2. Validate Migration Integrity

```bash
bin/rails migration:validate
```

### 3. Run Migration

```bash
bin/rails migration:migrate_users
```

### 4. Check Migration Status

```bash
bin/rails migration:stats
```

### 5. Rollback (if needed)

```bash
bin/rails migration:rollback
```

## Migration Process

### Pre-Migration Checklist

- [ ] Backup database
- [ ] Check current user statistics
- [ ] Validate data integrity
- [ ] Notify users (optional)

### Migration Steps

1. **Start Migration Tracking**: Creates migration status record
2. **Identify Users**: Finds users who need migration
3. **Migrate Premium Users**: Sets device_downloaded = true
4. **Migrate Free Users**: Starts 30-day trial
5. **Track Results**: Records success/failure counts
6. **Complete Tracking**: Marks migration as completed

### Post-Migration Checklist

- [ ] Verify migration results
- [ ] Check user statistics
- [ ] Test user access
- [ ] Monitor for issues

## Data Cleanup

### Daily Cleanup Job

- **Schedule**: Runs at 2am daily
- **Purpose**: Clean up expired trial data
- **Actions**:
  - Archive data for expired trial users
  - Clean up old download tokens
  - Mark trial data as exported

### Manual Cleanup

```bash
# Run cleanup job manually
bin/rails runner "TrialCleanupJob.perform_now"
```

## Monitoring

### Migration Status

Check migration status in the database:

```ruby
MigrationStatus.current_status('user_migration')
```

### User Statistics

```ruby
UserMigrationService.migration_stats
```

### Trial Status

```ruby
# Users on trial
User.where(trial_started_at: Time.current..).where(device_downloaded: false)

# Expired trials
User.where(trial_expires_at: ..Time.current).where(device_downloaded: false)

# Downloaded apps
User.where(device_downloaded: true)
```

## Troubleshooting

### Common Issues

1. **Migration Fails**

   - Check logs for specific errors
   - Validate data integrity
   - Check database constraints

2. **Users Can't Access App**

   - Verify trial dates are set correctly
   - Check device_downloaded status
   - Verify user model methods

3. **Data Inconsistencies**
   - Run validation command
   - Check for orphaned records
   - Verify foreign key constraints

### Recovery Procedures

1. **Rollback Migration**

   ```bash
   bin/rails migration:rollback
   ```

2. **Fix Individual User**

   ```ruby
   user = User.find(user_id)
   UserMigrationService.migrate_user(user)
   ```

3. **Reset Migration Status**
   ```ruby
   MigrationStatus.where(migration_type: 'user_migration').destroy_all
   ```

## Safety Measures

### Data Protection

- All user data is preserved
- No data is deleted during migration
- Expired trial data is archived before cleanup

### Rollback Capability

- Full rollback available
- Individual user fixes possible
- Migration status tracking

### Monitoring

- Comprehensive logging
- Status tracking
- Error reporting

## Testing

### Test Migration

```bash
# Run in test environment
RAILS_ENV=test bin/rails migration:migrate_users
```

### Validate Results

```bash
bin/rails migration:validate
```

### Check Statistics

```bash
bin/rails migration:stats
```

## Support

If you encounter issues during migration:

1. Check the logs for detailed error messages
2. Run validation commands to identify problems
3. Use rollback if necessary
4. Contact support with specific error details

## Migration Timeline

### Recommended Schedule

1. **Week 1**: Test migration in development
2. **Week 2**: Run migration in staging
3. **Week 3**: Execute production migration
4. **Week 4**: Monitor and cleanup

### Rollback Window

- Keep rollback capability for 30 days
- Monitor user feedback closely
- Be prepared to rollback if issues arise
