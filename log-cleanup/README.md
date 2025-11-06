# Log Cleanup Scripts

Automated log file management and cleanup to prevent disk space issues.

## Scripts

### 1. cleanup_logs.sh
Bash script for cleaning up old log files with compression and rotation.

**Features:**
- Configurable retention period
- Automatic compression of old logs
- Safe deletion with dry-run mode
- Preserves recent logs
- Supports multiple log directories

**Usage:**
```bash
# Default cleanup (30 days)
./cleanup_logs.sh

# Custom retention period
./cleanup_logs.sh 7

# Dry run (see what would be deleted)
DRY_RUN=true ./cleanup_logs.sh
```

**Cron Example:**
```bash
# Weekly cleanup at 3 AM on Sunday
0 3 * * 0 /path/to/cleanup_logs.sh
```

## Configuration

### Log Directories

Edit `cleanup_logs.sh` to add your log directories:
```bash
LOG_DIRS=(
    "/var/log"
    "/var/log/nginx"
    "/var/log/apache2"
    "/home/user/app/logs"
)
```

### Retention Settings
```bash
RETENTION_DAYS=30        # Delete logs older than 30 days
COMPRESS_DAYS=7          # Compress logs older than 7 days
```

## What Gets Cleaned

- `*.log` files
- `*.log.*` rotated files
- Compressed logs (`.gz`, `.zip`)
- Application-specific logs

## What's Preserved

- Current log files (< 1 day old)
- System critical logs
- Files within retention period

## Safety Features

- Dry-run mode to preview actions
- Backup before deletion (optional)
- Excludes critical system logs
- Detailed logging of actions

## Disk Space Recovery

Before cleanup:
```bash
du -sh /var/log
# 15G    /var/log
```

After cleanup:
```bash
du -sh /var/log
# 2.1G   /var/log
```

## Monitoring

Check cleanup logs:
```bash
tail -f /var/log/log-cleanup.log
```
