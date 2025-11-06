# Backup Automation Scripts

Automated backup solutions for databases and files with rotation policies.

## Scripts

### 1. backup_database.sh
PostgreSQL/MySQL database backup with compression and rotation.

**Features:**
- Automatic compression (gzip)
- 7-day rotation policy
- Timestamped backups
- Error handling

**Usage:**
```bash
./backup_database.sh [database_name]
```

**Cron Example:**
```bash
# Daily backup at 2 AM
0 2 * * * /path/to/backup_database.sh mydb
```

### 2. backup_files.py
Python script for backing up directories with optional encryption.

**Features:**
- Recursive directory backup
- Compression support
- Exclude patterns
- Backup verification

**Usage:**
```bash
python3 backup_files.py --source /path/to/source --dest /path/to/backup
```

## Configuration

Edit the scripts to customize:
- Backup directory location
- Retention period
- Compression level
- Database connection details

## Requirements
```bash
# For PostgreSQL
sudo apt-get install postgresql-client

# For MySQL
sudo apt-get install mysql-client

# Python dependencies
pip3 install psutil
```
