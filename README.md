# Automation Scripts Collection

Collection of production-ready automation scripts for Linux systems. Designed for system administrators, DevOps engineers, and anyone looking to automate repetitive tasks.

## 🚀 Features

- **Database Backup Automation** - Automated PostgreSQL/MySQL backups with rotation
- **Server Monitoring** - Resource monitoring with email alerts
- **Log Management** - Automated log cleanup and archiving
- **File Processing** - Batch file operations and CSV processing

## 🛠️ Technologies

- Python 3.x
- Bash
- Linux (Ubuntu/Debian/RHEL compatible)
- Cron/Systemd scheduling
- PowerShell (cross-platform)

## 📋 Requirements

### System Requirements
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install python3 python3-pip postgresql-client mysql-client

# RHEL/CentOS
sudo yum install python3 python3-pip postgresql mysql
```

### Python Requirements
```bash
pip3 install psutil requests pandas
```

## 📁 Project Structure
```
automation-scripts/
├── backup-automation/     # Database and file backup scripts
├── server-monitoring/     # System resource monitoring
├── log-cleanup/          # Log management and cleanup
└── file-processing/      # Batch file operations
```

## 🎯 Use Cases

- DevOps automation
- System administration
- Data operations
- Server maintenance
- Scheduled tasks
- Resource monitoring

## 🔧 Quick Start

Each subdirectory contains its own README with specific instructions. General usage:
```bash
# Make scripts executable
chmod +x script-name.sh

# Run a script
./script-name.sh

# Schedule with cron
crontab -e
# Add: 0 2 * * * /path/to/script.sh
```

## 📝 License

MIT License - Free for personal and commercial use

## 👤 Author

Available for freelance automation projects. Specialized in:
- Linux system automation
- Database operations
- Server monitoring
- ETL pipelines

## 🤝 Contributing

Feel free to fork, modify, and use these scripts for your own projects!
