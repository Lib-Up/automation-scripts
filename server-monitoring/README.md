# Server Monitoring Scripts

Real-time server resource monitoring with alerting capabilities.

## Scripts

### 1. monitor_resources.sh
Bash script for monitoring CPU, Memory, and Disk usage.

**Features:**
- Configurable thresholds
- Real-time alerts
- Logging support
- Email notifications (optional)

**Usage:**
```bash
./monitor_resources.sh
```

**Cron Example:**
```bash
# Check every 5 minutes
*/5 * * * * /path/to/monitor_resources.sh
```

### 2. alert_email.py
Python script for sending email alerts when thresholds are exceeded.

**Features:**
- SMTP support
- HTML email templates
- Multiple recipients
- Retry logic

**Usage:**
```bash
python3 alert_email.py --subject "Server Alert" --message "High CPU usage"
```

## Configuration

### Environment Variables
```bash
export ALERT_EMAIL="admin@example.com"
export SMTP_SERVER="smtp.gmail.com"
export SMTP_PORT="587"
export SMTP_USER="your-email@gmail.com"
export SMTP_PASSWORD="your-app-password"
```

### Thresholds

Edit `monitor_resources.sh`:
```bash
CPU_THRESHOLD=80
MEM_THRESHOLD=80
DISK_THRESHOLD=90
```

## Requirements
```bash
# System tools (usually pre-installed)
which top free df

# For email alerts
pip3 install requests
```

## Logs

Monitoring logs are stored in:
```
/var/log/server-monitor/monitor.log
```
