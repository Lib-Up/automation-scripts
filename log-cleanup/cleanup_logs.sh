
#!/bin/bash

#############################################
# Log Cleanup Script
# Cleans up old log files and compresses them
# Prevents disk space issues
#############################################

set -e

# Configuration
RETENTION_DAYS=${1:-30}
COMPRESS_DAYS=${COMPRESS_DAYS:-7}
DRY_RUN=${DRY_RUN:-false}
LOG_FILE="/var/log/log-cleanup.log"

# Log directories to clean (customize as needed)
LOG_DIRS=(
    "/var/log"
    "/var/log/nginx"
    "/var/log/apache2"
)

# Files to exclude from cleanup
EXCLUDE_PATTERNS=(
    "syslog"
    "kern.log"
    "auth.log"
    "dmesg"
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Statistics
TOTAL_FILES_DELETED=0
TOTAL_FILES_COMPRESSED=0
TOTAL_SPACE_FREED=0

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if file should be excluded
should_exclude() {
    local file="$1"
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        if [[ "$file" == *"$pattern"* ]]; then
            return 0
        fi
    done
    return 1
}

# Get file size in bytes
get_file_size() {
    stat -f%z "$1" 2>/dev/null || stat -c%s "$1" 2>/dev/null || echo 0
}

# Human readable size
human_size() {
    local bytes=$1
    if [ "$bytes" -lt 1024 ]; then
        echo "${bytes}B"
    elif [ "$bytes" -lt 1048576 ]; then
        echo "$((bytes / 1024))KB"
    elif [ "$bytes" -lt 1073741824 ]; then
        echo "$((bytes / 1048576))MB"
    else
        echo "$((bytes / 1073741824))GB"
    fi
}

# Compress old logs
compress_logs() {
    local dir="$1"
    
    log "Compressing logs older than ${COMPRESS_DAYS} days in ${dir}..."
    
    # Find uncompressed log files older than COMPRESS_DAYS
    while IFS= read -r -d '' file; do
        if should_exclude "$file"; then
            continue
        fi
        
        # Skip if already compressed
        if [[ "$file" == *.gz ]] || [[ "$file" == *.zip ]]; then
            continue
        fi
        
        local size_before=$(get_file_size "$file")
        
        if [ "$DRY_RUN" = "true" ]; then
            echo -e "${YELLOW}[DRY RUN] Would compress: $file${NC}"
        else
            gzip -f "$file" 2>/dev/null && {
                log "Compressed: $file"
                TOTAL_FILES_COMPRESSED=$((TOTAL_FILES_COMPRESSED + 1))
                echo -e "${GREEN}✓ Compressed: $(basename "$file")${NC}"
            }
        fi
    done < <(find "$dir" -maxdepth 2 -type f \( -name "*.log" -o -name "*.log.*" \) -mtime +${COMPRESS_DAYS} -print0 2>/dev/null)
}

# Delete old logs
delete_old_logs() {
    local dir="$1"
    
    log "Deleting logs older than ${RETENTION_DAYS} days in ${dir}..."
    
    # Find log files older than RETENTION_DAYS
    while IFS= read -r -d '' file; do
        if should_exclude "$file"; then
            continue
        fi
        
        local size=$(get_file_size "$file")
        TOTAL_SPACE_FREED=$((TOTAL_SPACE_FREED + size))
        
        if [ "$DRY_RUN" = "true" ]; then
            echo -e "${YELLOW}[DRY RUN] Would delete: $file ($(human_size $size))${NC}"
        else
            rm -f "$file" 2>/dev/null && {
                log "Deleted: $file ($(human_size $size))"
                TOTAL_FILES_DELETED=$((TOTAL_FILES_DELETED + 1))
                echo -e "${RED}✓ Deleted: $(basename "$file") ($(human_size $size))${NC}"
            }
        fi
    done < <(find "$dir" -maxdepth 2 -type f \( -name "*.log" -o -name "*.log.*" -o -name "*.gz" \) -mtime +${RETENTION_DAYS} -print0 2>/dev/null)
}

# Display disk usage
show_disk_usage() {
    local dir="$1"
    if [ -d "$dir" ]; then
        local usage=$(du -sh "$dir" 2>/dev/null | cut -f1)
        echo -e "${BLUE}  $dir: $usage${NC}"
    fi
}

# Main function
main() {
    echo "=================================="
    echo "  Log Cleanup Script"
    echo "=================================="
    echo "Retention: ${RETENTION_DAYS} days"
    echo "Compress after: ${COMPRESS_DAYS} days"
    echo "Dry run: ${DRY_RUN}"
    echo "=================================="
    
    log "=== Starting log cleanup ==="
    log "Retention period: ${RETENTION_DAYS} days"
    log "Compression period: ${COMPRESS_DAYS} days"
    log "Dry run: ${DRY_RUN}"
    
    # Show disk usage before
    echo ""
    echo "Disk usage BEFORE cleanup:"
    for dir in "${LOG_DIRS[@]}"; do
        show_disk_usage "$dir"
    done
    echo ""
    
    # Process each log directory
    for dir in "${LOG_DIRS[@]}"; do
        if [ ! -d "$dir" ]; then
            log "Directory not found: $dir"
            continue
        fi
        
        echo -e "${BLUE}Processing: $dir${NC}"
        
        # Compress old logs first
        compress_logs "$dir"
        
        # Delete very old logs
        delete_old_logs "$dir"
        
        echo ""
    done
    
    # Show disk usage after
    echo "Disk usage AFTER cleanup:"
    for dir in "${LOG_DIRS[@]}"; do
        show_disk_usage "$dir"
    done
    echo ""
    
    # Summary
    echo "=================================="
    echo "  Cleanup Summary"
    echo "=================================="
    echo "Files compressed: ${TOTAL_FILES_COMPRESSED}"
    echo "Files deleted: ${TOTAL_FILES_DELETED}"
    echo "Space freed: $(human_size ${TOTAL_SPACE_FREED})"
    echo "=================================="
    
    log "=== Cleanup complete ==="
    log "Files compressed: ${TOTAL_FILES_COMPRESSED}"
    log "Files deleted: ${TOTAL_FILES_DELETED}"
    log "Space freed: $(human_size ${TOTAL_SPACE_FREED})"
    
    if [ "$DRY_RUN" = "true" ]; then
        echo ""
        echo -e "${YELLOW}This was a DRY RUN. No files were actually modified.${NC}"
        echo -e "${YELLOW}Run without DRY_RUN=true to perform actual cleanup.${NC}"
    fi
}

# Check if running as root (recommended for system logs)
if [ "$EUID" -ne 0 ] && [[ "${LOG_DIRS[*]}" == *"/var/log"* ]]; then
    echo -e "${YELLOW}Warning: Not running as root. Some log directories may not be accessible.${NC}"
    echo "Consider running with: sudo $0"
    echo ""
fi

# Run main function
main

exit 0
