# File Processing Scripts

Batch file operations and CSV processing utilities.

## Scripts

### 1. process_csv.py
Python script for processing and transforming CSV files.

**Features:**
- Read large CSV files efficiently
- Data transformation and filtering
- Column operations
- Export to multiple formats (CSV, Excel, JSON)
- Data validation

**Usage:**
```bash
# Basic processing
python3 process_csv.py --input data.csv --output processed.csv

# Filter rows
python3 process_csv.py --input data.csv --filter "age > 18"

# Select columns
python3 process_csv.py --input data.csv --columns "name,age,email"

# Convert to Excel
python3 process_csv.py --input data.csv --output data.xlsx
```

### 2. batch_rename.sh
Bash script for batch renaming files with patterns.

**Features:**
- Multiple rename patterns
- Dry-run mode
- Backup option
- Recursive processing
- Undo capability

**Usage:**
```bash
# Replace spaces with underscores
./batch_rename.sh --pattern " " --replace "_" --dir /path/to/files

# Add prefix to all files
./batch_rename.sh --prefix "backup_" --dir /path/to/files

# Change extension
./batch_rename.sh --old-ext "txt" --new-ext "md" --dir /path/to/files

# Dry run (preview changes)
./batch_rename.sh --pattern "old" --replace "new" --dir /path/to/files --dry-run
```

## Use Cases

### CSV Processing
- Data cleaning and validation
- Format conversion
- Column transformations
- Large file handling
- Batch data processing

### Batch Renaming
- Organize media files
- Standardize naming conventions
- Clean up filenames
- Prepare files for upload
- Archive organization

## Requirements
```bash
# For CSV processing
pip3 install pandas openpyxl

# For batch rename (no additional requirements)
# Uses standard bash utilities
```

## Examples

### Process CSV
```python
# Example: Filter and transform
python3 process_csv.py \
    --input sales.csv \
    --filter "revenue > 1000" \
    --columns "date,customer,revenue" \
    --sort "revenue" \
    --output top_sales.csv
```

### Batch Rename
```bash
# Example: Clean up photo filenames
./batch_rename.sh \
    --pattern "IMG_" \
    --replace "photo_" \
    --dir ~/Pictures/vacation \
    --dry-run
```

## Safety Features

- Dry-run mode to preview changes
- Automatic backups (optional)
- Validation before processing
- Detailed logs
- Undo capability
