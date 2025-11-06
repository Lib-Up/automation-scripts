#!/usr/bin/env python3
"""
File Backup Script
Automated file and directory backup with compression
"""

import os
import sys
import shutil
import argparse
import tarfile
import logging
from datetime import datetime
from pathlib import Path

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class FileBackup:
    """Handle file and directory backups"""
    
    def __init__(self, source, destination, exclude_patterns=None):
        self.source = Path(source)
        self.destination = Path(destination)
        self.exclude_patterns = exclude_patterns or []
        self.timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        
    def validate_paths(self):
        """Validate source and destination paths"""
        if not self.source.exists():
            raise FileNotFoundError(f"Source path does not exist: {self.source}")
        
        # Create destination if it doesn't exist
        self.destination.mkdir(parents=True, exist_ok=True)
        logger.info(f"Backup destination: {self.destination}")
        
    def should_exclude(self, path):
        """Check if path should be excluded"""
        path_str = str(path)
        for pattern in self.exclude_patterns:
            if pattern in path_str:
                return True
        return False
    
    def create_archive(self):
        """Create compressed tar archive of source"""
        source_name = self.source.name
        archive_name = f"{source_name}_backup_{self.timestamp}.tar.gz"
        archive_path = self.destination / archive_name
        
        logger.info(f"Creating archive: {archive_name}")
        
        try:
            with tarfile.open(archive_path, "w:gz") as tar:
                tar.add(
                    self.source,
                    arcname=source_name,
                    filter=lambda x: None if self.should_exclude(x.name) else x
                )
            
            # Get archive size
            size_mb = archive_path.stat().st_size / (1024 * 1024)
            logger.info(f"✓ Backup created: {archive_path} ({size_mb:.2f} MB)")
            
            return archive_path
            
        except Exception as e:
            logger.error(f"Failed to create archive: {e}")
            raise
    
    def verify_backup(self, archive_path):
        """Verify the backup archive"""
        logger.info("Verifying backup integrity...")
        
        try:
            with tarfile.open(archive_path, "r:gz") as tar:
                members = tar.getmembers()
                logger.info(f"✓ Archive contains {len(members)} files/directories")
                return True
        except Exception as e:
            logger.error(f"Backup verification failed: {e}")
            return False
    
    def cleanup_old_backups(self, retention_days=7):
        """Remove backups older than retention period"""
        logger.info(f"Cleaning up backups older than {retention_days} days...")
        
        cutoff_time = datetime.now().timestamp() - (retention_days * 86400)
        deleted_count = 0
        
        for backup_file in self.destination.glob("*_backup_*.tar.gz"):
            if backup_file.stat().st_mtime < cutoff_time:
                backup_file.unlink()
                deleted_count += 1
                logger.info(f"Deleted old backup: {backup_file.name}")
        
        logger.info(f"✓ Deleted {deleted_count} old backup(s)")
    
    def run(self, verify=True, cleanup=True, retention_days=7):
        """Execute backup process"""
        logger.info("=" * 60)
        logger.info("Starting File Backup")
        logger.info("=" * 60)
        logger.info(f"Source: {self.source}")
        logger.info(f"Destination: {self.destination}")
        
        try:
            # Validate
            self.validate_paths()
            
            # Create backup
            archive_path = self.create_archive()
            
            # Verify if requested
            if verify:
                if not self.verify_backup(archive_path):
                    raise Exception("Backup verification failed")
            
            # Cleanup old backups
            if cleanup:
                self.cleanup_old_backups(retention_days)
            
            logger.info("=" * 60)
            logger.info("✓ Backup completed successfully")
            logger.info("=" * 60)
            
            return archive_path
            
        except Exception as e:
            logger.error(f"Backup failed: {e}")
            sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description='Automated file backup with compression'
    )
    parser.add_argument(
        '--source', '-s',
        required=True,
        help='Source directory to backup'
    )
    parser.add_argument(
        '--dest', '-d',
        required=True,
        help='Destination directory for backups'
    )
    parser.add_argument(
        '--exclude', '-e',
        nargs='*',
        default=[],
        help='Patterns to exclude (e.g., __pycache__ .git)'
    )
    parser.add_argument(
        '--retention-days', '-r',
        type=int,
        default=7,
        help='Number of days to retain backups (default: 7)'
    )
    parser.add_argument(
        '--no-verify',
        action='store_true',
        help='Skip backup verification'
    )
    parser.add_argument(
        '--no-cleanup',
        action='store_true',
        help='Skip cleanup of old backups'
    )
    
    args = parser.parse_args()
    
    # Create and run backup
    backup = FileBackup(
        source=args.source,
        destination=args.dest,
        exclude_patterns=args.exclude
    )
    
    backup.run(
        verify=not args.no_verify,
        cleanup=not args.no_cleanup,
        retention_days=args.retention_days
    )


if __name__ == "__main__":
    main()
