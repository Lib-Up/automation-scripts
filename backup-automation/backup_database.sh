
#!/bin/bash

#############################################
# Database Backup Script
# Supports PostgreSQL and MySQL
# Features: Compression, Rotation, Logging
#############################################

set -e  # Exit on error

# Configuration
DB_TYPE="${DB_TYPE:-postgres}"  # postgres or mysql
DB_NAME="${1:-mydb}"
DB_USER="${DB_USER:-postgres}"
DB_HOST="${DB_HOST:-localhost}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/database}"
RETENTION_DAYS=7
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${BACKUP_DIR}/backup.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    log "ERROR: $1"
    exit 1
}

# Create backup directory
mkdir -p "${BACKUP_DIR}" || error_exit "Failed to create backup directory"

log "Starting backup for database: ${DB_NAME}"

# Perform backup based on database type
if [ "$DB_TYPE" = "postgres" ]; then
    BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${DATE}.sql.gz"
    
    log "Performing PostgreSQL backup..."
    PGPASSWORD="${DB_PASSWORD}" pg_dump \
        -h "${DB_HOST}" \
        -U "${DB_USER}" \
        "${DB_NAME}" | gzip > "${BACKUP_FILE}" \
        || error_exit "PostgreSQL backup failed"
        
elif [ "$DB_TYPE" = "mysql" ]; then
    BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${DATE}.sql.gz"
    
    log "Performing MySQL backup..."
    mysqldump \
        -h "${DB_HOST}" \
        -u "${DB_USER}" \
        -p"${DB_PASSWORD}" \
        "${DB_NAME}" | gzip > "${BACKUP_FILE}" \
        || error_exit "MySQL backup failed"
else
    error_exit "Unsupported database type: ${DB_TYPE}"
fi

# Verify backup file exists and has size > 0
if [ ! -s "${BACKUP_FILE}" ]; then
    error_exit "Backup file is empty or doesn't exist"
fi

BACKUP_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
log "Backup completed successfully: ${BACKUP_FILE} (${BACKUP_SIZE})"

# Cleanup old backups
log "Cleaning up backups older than ${RETENTION_DAYS} days..."
find "${BACKUP_DIR}" -name "*.sql.gz" -type f -mtime +${RETENTION_DAYS} -delete
DELETED_COUNT=$(find "${BACKUP_DIR}" -name "*.sql.gz" -type f -mtime +${RETENTION_DAYS} 2>/dev/null | wc -l)
log "Deleted ${DELETED_COUNT} old backup(s)"

# Summary
TOTAL_BACKUPS=$(find "${BACKUP_DIR}" -name "*.sql.gz" -type f | wc -l)
TOTAL_SIZE=$(du -sh "${BACKUP_DIR}" | cut -f1)

echo -e "${GREEN}✓ Backup Summary:${NC}"
echo "  Database: ${DB_NAME}"
echo "  Backup File: ${BACKUP_FILE}"
echo "  Size: ${BACKUP_SIZE}"
echo "  Total Backups: ${TOTAL_BACKUPS}"
echo "  Total Size: ${TOTAL_SIZE}"

log "Backup process completed successfully"
exit 0
