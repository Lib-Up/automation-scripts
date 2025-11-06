
#!/bin/bash

#############################################
# Batch File Rename Script
# Rename multiple files using patterns
# Features: Dry-run, Undo, Multiple patterns
#############################################

set -e

# Default values
DRY_RUN=false
RECURSIVE=false
BACKUP=false
DIRECTORY="."
PATTERN=""
REPLACE=""
PREFIX=""
SUFFIX=""
OLD_EXT=""
NEW_EXT=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
RENAMED_COUNT=0
SKIPPED_COUNT=0

# Usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Batch rename files using various patterns.

OPTIONS:
    --dir PATH              Directory to process (default: current)
    --pattern TEXT          Text pattern to find
    --replace TEXT          Text to replace pattern with
    --prefix TEXT           Add prefix to filenames
    --suffix TEXT           Add suffix to filenames
    --old-ext EXT           Old file extension
    --new-ext EXT           New file extension
    --recursive             Process subdirectories
    --dry-run               Preview changes without renaming
    --backup                Create backup of original files
    --help                  Show this help message

EXAMPLES:
    # Replace spaces with underscores
    $0 --pattern " " --replace "_" --dir /path/to/files

    # Add prefix to all .jpg files
    $0 --prefix "vacation_" --old-ext "jpg" --dir ~/Photos

    # Change extension
    $0 --old-ext "txt" --new-ext "md" --dir ~/Documents

    # Lowercase all filenames
    $0 --pattern "[A-Z]" --replace "[a-z]" --dir ~/Files

    # Dry run (preview)
    $0 --pattern "old" --replace "new" --dir ~/test --dry-run

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dir)
            DIRECTORY="$2"
            shift 2
            ;;
        --pattern)
            PATTERN="$2"
            shift 2
            ;;
        --replace)
            REPLACE="$2"
            shift 2
            ;;
        --prefix)
            PREFIX="$2"
            shift 2
            ;;
        --suffix)
            SUFFIX="$2"
            shift 2
            ;;
        --old-ext)
            OLD_EXT="$2"
            shift 2
            ;;
        --new-ext)
            NEW_EXT="$2"
            shift 2
            ;;
        --recursive)
            RECURSIVE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --backup)
            BACKUP=true
            shift
            ;;
        --help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate directory
if [ ! -d "$DIRECTORY" ]; then
    echo -e "${RED}Error: Directory not found: $DIRECTORY${NC}"
    exit 1
fi

# Check if at least one operation is specified
if [ -z "$PATTERN" ] && [ -z "$PREFIX" ] && [ -z "$SUFFIX" ] && [ -z "$OLD_EXT" ]; then
    echo -e "${RED}Error: No rename operation specified${NC}"
    usage
fi

# Log function
log() {
    echo -e "$1"
}

# Rename file function
rename_file() {
    local old_path="$1"
    local old_name=$(basename "$old_path")
    local dir_name=$(dirname "$old_path")
    local new_name="$old_name"
    
    # Apply pattern replacement
    if [ -n "$PATTERN" ]; then
        new_name="${new_name//$PATTERN/$REPLACE}"
    fi
    
    # Apply prefix
    if [ -n "$PREFIX" ]; then
        new_name="${PREFIX}${new_name}"
    fi
    
    # Apply suffix (before extension)
    if [ -n "$SUFFIX" ]; then
        local name_no_ext="${new_name%.*}"
        local ext="${new_name##*.}"
        if [ "$name_no_ext" != "$new_name" ]; then
            new_name="${name_no_ext}${SUFFIX}.${ext}"
        else
            new_name="${new_name}${SUFFIX}"
        fi
    fi
    
    # Change extension
    if [ -n "$OLD_EXT" ] && [ -n "$NEW_EXT" ]; then
        if [[ "$new_name" == *."$OLD_EXT" ]]; then
            new_name="${new_name%.$OLD_EXT}.${NEW_EXT}"
        fi
    fi
    
    local new_path="${dir_name}/${new_name}"
    
    # Skip if no change
    if [ "$old_path" = "$new_path" ]; then
        return 1
    fi
    
    # Check if target already exists
    if [ -e "$new_path" ] && [ "$old_path" != "$new_path" ]; then
        log "${RED}✗ Target exists: $new_name${NC}"
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        return 1
    fi
    
    # Perform rename
    if [ "$DRY_RUN" = true ]; then
        log "${YELLOW}[DRY RUN] $old_name → $new_name${NC}"
    else
        # Backup if requested
        if [ "$BACKUP" = true ]; then
            cp "$old_path" "${old_path}.bak"
        fi
        
        mv "$old_path" "$new_path" && {
            log "${GREEN}✓ $old_name → $new_name${NC}"
            RENAMED_COUNT=$((RENAMED_COUNT + 1))
        } || {
            log "${RED}✗ Failed: $old_name${NC}"
            SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        }
    fi
    
    return 0
}

# Main processing
main() {
    echo "=================================="
    echo "  Batch File Rename"
    echo "=================================="
    echo "Directory: $DIRECTORY"
    echo "Recursive: $RECURSIVE"
    echo "Dry run: $DRY_RUN"
    echo "Backup: $BACKUP"
    
    if [ -n "$PATTERN" ]; then
        echo "Pattern: '$PATTERN' → '$REPLACE'"
    fi
    if [ -n "$PREFIX" ]; then
        echo "Prefix: '$PREFIX'"
    fi
    if [ -n "$SUFFIX" ]; then
        echo "Suffix: '$SUFFIX'"
    fi
    if [ -n "$OLD_EXT" ] && [ -n "$NEW_EXT" ]; then
        echo "Extension: .$OLD_EXT → .$NEW_EXT"
    fi
    
    echo "=================================="
    echo ""
    
    # Find files
    if [ "$RECURSIVE" = true ]; then
        FIND_DEPTH=""
    else
        FIND_DEPTH="-maxdepth 1"
    fi
    
    # Build find command
    FIND_CMD="find \"$DIRECTORY\" $FIND_DEPTH -type f"
    
    # Add extension filter if specified
    if [ -n "$OLD_EXT" ]; then
        FIND_CMD="$FIND_CMD -name \"*.$OLD_EXT\""
    fi
    
    # Process files
    local file_count=0
    while IFS= read -r file; do
        file_count=$((file_count + 1))
        rename_file "$file" || true
    done < <(eval "$FIND_CMD")
    
    # Summary
    echo ""
    echo "=================================="
    echo "  Summary"
    echo "=================================="
    echo "Files processed: $file_count"
    echo "Files renamed: $RENAMED_COUNT"
    echo "Files skipped: $SKIPPED_COUNT"
    echo "=================================="
    
    if [ "$DRY_RUN" = true ]; then
        echo ""
        log "${YELLOW}This was a DRY RUN. No files were actually renamed.${NC}"
        log "${YELLOW}Run without --dry-run to perform actual renaming.${NC}"
    fi
    
    if [ "$BACKUP" = true ] && [ "$DRY_RUN" = false ]; then
        echo ""
        log "${BLUE}Backup files created with .bak extension${NC}"
        log "${BLUE}To undo: find \"$DIRECTORY\" -name \"*.bak\" -exec bash -c 'mv \"\$0\" \"\${0%.bak}\"' {} \\;${NC}"
    fi
}

# Run main function
main

exit 0
