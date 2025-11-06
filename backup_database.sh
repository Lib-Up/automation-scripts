#!/bin/bash

# Database Backup Script
# Usage: ./backup_database.sh [database_name]

DB_NAME=${1:-mydb}
BACKUP_DIR="/var/backups/postgres"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${DATE}.sql.gz"

# Create backup directory
mkdir -p "${BACKUP_DIR}"

# Perform backup
pg_dump "${DB_NAME}" | gzip > "${BACKUP_FILE}"

# Keep only last 7 days
find "${BACKUP_DIR}" -name "*.sql.gz" -mtime +7 -delete

echo "Backup completed: ${BACKUP_FILE}"
