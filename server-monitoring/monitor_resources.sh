#!/bin/bash

#############################################
# Server Resource Monitoring Script
# Monitors: CPU, Memory, Disk, Load Average
# Sends alerts when thresholds are exceeded
#############################################

set -e

# Configuration
CPU_THRESHOLD=${CPU_THRESHOLD:-80}
MEM_THRESHOLD=${MEM_THRESHOLD:-80}
DISK_THRESHOLD=${DISK_THRESHOLD:-90}
LOAD_THRESHOLD=${LOAD_THRESHOLD:-4.0}
LOG_FILE="${LOG_FILE:-/var/log/server-monitor/monitor.log}"
ALERT_EMAIL="${ALERT_EMAIL:-admin@example.com}"
SEND_EMAIL=${SEND_EMAIL:-false}

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Create log directory
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Alert function
send_alert() {
    local subject="$1"
    local message="$2"
    
    echo -e "${RED}⚠ ALERT: ${subject}${NC}"
    log "ALERT: ${subject} - ${message}"
    
    if [ "$SEND_EMAIL" = "true" ]; then
        # Send email using Python script
        python3 "$(dirname "$0")/alert_email.py" \
            --subject "Server Alert: ${subject}" \
            --message "${message}" \
            --to "${ALERT_EMAIL}" 2>/dev/null || true
    fi
}

# Get CPU usage
get_cpu_usage() {
    # Method 1: Using top
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
    
    # Method 2: Using mpstat (if available)
    # mpstat 1 1 | awk '/Average/ {print 100 - $NF}'
}

# Get Memory usage
get_memory_usage() {
    free | grep Mem | awk '{printf "%.0f", ($3/$2) * 100.0}'
}

# Get Disk usage
get_disk_usage() {
    df -h / | tail -1 | awk '{print $5}' | cut -d'%' -f1
}

# Get Load Average
get_load_average() {
    uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ','
}

# Main monitoring function
monitor() {
    log "=== Server Resource Check ==="
    
    # CPU Check
    CPU_USAGE=$(get_cpu_usage)
    CPU_USAGE_INT=${CPU_USAGE%.*}
    log "CPU Usage: ${CPU_USAGE}%"
    
    if [ "$CPU_USAGE_INT" -gt "$CPU_THRESHOLD" ]; then
        send_alert "High CPU Usage" "CPU usage is at ${CPU_USAGE}% (threshold: ${CPU_THRESHOLD}%)"
    else
        echo -e "${GREEN}✓ CPU: ${CPU_USAGE}%${NC}"
    fi
    
    # Memory Check
    MEM_USAGE=$(get_memory_usage)
    log "Memory Usage: ${MEM_USAGE}%"
    
    if [ "$MEM_USAGE" -gt "$MEM_THRESHOLD" ]; then
        send_alert "High Memory Usage" "Memory usage is at ${MEM_USAGE}% (threshold: ${MEM_THRESHOLD}%)"
    else
        echo -e "${GREEN}✓ Memory: ${MEM_USAGE}%${NC}"
    fi
    
    # Disk Check
    DISK_USAGE=$(get_disk_usage)
    log "Disk Usage: ${DISK_USAGE}%"
    
    if [ "$DISK_USAGE" -gt "$DISK_THRESHOLD" ]; then
        send_alert "High Disk Usage" "Disk usage is at ${DISK_USAGE}% (threshold: ${DISK_THRESHOLD}%)"
    else
        echo -e "${GREEN}✓ Disk: ${DISK_USAGE}%${NC}"
    fi
    
    # Load Average Check
    LOAD_AVG=$(get_load_average)
    log "Load Average: ${LOAD_AVG}"
    
    if (( $(echo "$LOAD_AVG > $LOAD_THRESHOLD" | bc -l 2>/dev/null || echo 0) )); then
        send_alert "High Load Average" "Load average is ${LOAD_AVG} (threshold: ${LOAD_THRESHOLD})"
    else
        echo -e "${GREEN}✓ Load: ${LOAD_AVG}${NC}"
    fi
    
    # System Info
    HOSTNAME=$(hostname)
    UPTIME=$(uptime -p 2>/dev/null || uptime | awk '{print $3,$4}')
    
    log "Hostname: ${HOSTNAME}"
    log "Uptime: ${UPTIME}"
    log "=== Check Complete ==="
    echo ""
}

# Display current status
display_status() {
    echo "================================"
    echo "  Server Resource Monitor"
    echo "================================"
    echo "Hostname: $(hostname)"
    echo "Time: $(date)"
    echo "--------------------------------"
    monitor
    echo "================================"
}

# Run monitoring
display_status

exit 0
