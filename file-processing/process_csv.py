#!/usr/bin/env python3
"""
CSV Processing Script
Advanced CSV file processing and transformation
"""

import pandas as pd
import argparse
import sys
import logging
from pathlib import Path

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class CSVProcessor:
    """Handle CSV file processing and transformations"""
    
    def __init__(self, input_file):
        self.input_file = Path(input_file)
        self.df = None
        self.original_rows = 0
        
    def load_csv(self, encoding='utf-8', delimiter=','):
        """Load CSV file into DataFrame"""
        try:
            logger.info(f"Loading CSV file: {self.input_file}")
            self.df = pd.read_csv(
                self.input_file,
                encoding=encoding,
                delimiter=delimiter,
                low_memory=False
            )
            self.original_rows = len(self.df)
            logger.info(f"✓ Loaded {self.original_rows} rows, {len(self.df.columns)} columns")
            return True
        except Exception as e:
            logger.error(f"Failed to load CSV: {e}")
            return False
    
    def show_info(self):
        """Display DataFrame information"""
        if self.df is None:
            return
        
        print("\n" + "=" * 60)
        print("CSV File Information")
        print("=" * 60)
        print(f"Rows: {len(self.df)}")
        print(f"Columns: {len(self.df.columns)}")
        print(f"\nColumn Names:")
        for i, col in enumerate(self.df.columns, 1):
            dtype = self.df[col].dtype
            null_count = self.df[col].isnull().sum()
            print(f"  {i}. {col} ({dtype}) - {null_count} nulls")
        print("=" * 60 + "\n")
    
    def select_columns(self, columns):
        """Select specific columns"""
        if not columns:
            return
        
        col_list = [c.strip() for c in columns.split(',')]
        
        # Check if all columns exist
        missing = set(col_list) - set(self.df.columns)
        if missing:
            logger.error(f"Columns not found: {missing}")
            return False
        
        logger.info(f"Selecting columns: {col_list}")
        self.df = self.df[col_list]
        return True
    
    def filter_rows(self, filter_expr):
        """Filter rows based on expression"""
        if not filter_expr:
            return True
        
        try:
            logger.info(f"Applying filter: {filter_expr}")
            initial_rows = len(self.df)
            self.df = self.df.query(filter_expr)
            filtered_rows = initial_rows - len(self.df)
            logger.info(f"✓ Filtered out {filtered_rows} rows, {len(self.df)} remaining")
            return True
        except Exception as e:
            logger.error(f"Filter failed: {e}")
            return False
    
    def sort_data(self, sort_column, ascending=True):
        """Sort DataFrame by column"""
        if not sort_column:
            return True
        
        if sort_column not in self.df.columns:
            logger.error(f"Sort column not found: {sort_column}")
            return False
        
        logger.info(f"Sorting by: {sort_column} ({'ascending' if ascending else 'descending'})")
        self.df = self.df.sort_values(by=sort_column, ascending=ascending)
        return True
    
    def remove_duplicates(self, subset=None):
        """Remove duplicate rows"""
        initial_rows = len(self.df)
        self.df = self.df.drop_duplicates(subset=subset)
        removed = initial_rows - len(self.df)
        if removed > 0:
            logger.info(f"✓ Removed {removed} duplicate rows")
        return True
    
    def fill_missing(self, method='drop', value=None):
        """Handle missing values"""
        null_count = self.df.isnull().sum().sum()
        
        if null_count == 0:
            logger.info("No missing values found")
            return True
        
        logger.info(f"Found {null_count} missing values")
        
        if method == 'drop':
            self.df = self.df.dropna()
            logger.info(f"✓ Dropped rows with missing values")
        elif method == 'fill':
            fill_value = value if value is not None else 0
            self.df = self.df.fillna(fill_value)
            logger.info(f"✓ Filled missing values with: {fill_value}")
        
        return True
    
    def save_file(self, output_file, file_format=None):
        """Save processed data to file"""
        output_path = Path(output_file)
        
        # Determine format from extension if not specified
        if file_format is None:
            file_format = output_path.suffix.lower().replace('.', '')
        
        try:
            logger.info(f"Saving to: {output_path} (format: {file_format})")
            
            if file_format in ['csv', 'txt']:
                self.df.to_csv(output_path, index=False)
            elif file_format in ['xlsx', 'excel']:
                self.df.to_excel(output_path, index=False, engine='openpyxl')
            elif file_format == 'json':
                self.df.to_json(output_path, orient='records', indent=2)
            else:
                logger.error(f"Unsupported format: {file_format}")
                return False
            
            file_size = output_path.stat().st_size / 1024
            logger.info(f"✓ File saved ({file_size:.2f} KB)")
            return True
            
        except Exception as e:
            logger.error(f"Failed to save file: {e}")
            return False
    
    def show_summary(self):
        """Display processing summary"""
        print("\n" + "=" * 60)
        print("Processing Summary")
        print("=" * 60)
        print(f"Original rows: {self.original_rows}")
        print(f"Final rows: {len(self.df)}")
        print(f"Rows processed: {self.original_rows - len(self.df)}")
        print(f"Final columns: {len(self.df.columns)}")
        print("=" * 60 + "\n")


def main():
    parser = argparse.ArgumentParser(
        description='CSV Processing and Transformation Tool'
    )
    parser.add_argument(
        '--input', '-i',
        required=True,
        help='Input CSV file'
    )
    parser.add_argument(
        '--output', '-o',
        required=True,
        help='Output file (CSV, Excel, JSON)'
    )
    parser.add_argument(
        '--columns', '-c',
        help='Comma-separated list of columns to select'
    )
    parser.add_argument(
        '--filter', '-f',
        help='Filter expression (e.g., "age > 18")'
    )
    parser.add_argument(
        '--sort',
        help='Column to sort by'
    )
    parser.add_argument(
        '--descending',
        action='store_true',
        help='Sort in descending order'
    )
    parser.add_argument(
        '--remove-duplicates',
        action='store_true',
        help='Remove duplicate rows'
    )
    parser.add_argument(
        '--fill-missing',
        choices=['drop', 'fill'],
        help='Handle missing values'
    )
    parser.add_argument(
        '--fill-value',
        help='Value to use when filling missing data'
    )
    parser.add_argument(
        '--info',
        action='store_true',
        help='Show CSV file information and exit'
    )
    parser.add_argument(
        '--delimiter',
        default=',',
        help='CSV delimiter (default: comma)'
    )
    parser.add_argument(
        '--encoding',
        default='utf-8',
        help='File encoding (default: utf-8)'
    )
    
    args = parser.parse_args()
    
    # Create processor
    processor = CSVProcessor(args.input)
    
    # Load CSV
    if not processor.load_csv(encoding=args.encoding, delimiter=args.delimiter):
        sys.exit(1)
    
    # Show info and exit if requested
    if args.info:
        processor.show_info()
        sys.exit(0)
    
    # Process data
    if args.columns:
        if not processor.select_columns(args.columns):
            sys.exit(1)
    
    if args.filter:
        if not processor.filter_rows(args.filter):
            sys.exit(1)
    
    if args.remove_duplicates:
        processor.remove_duplicates()
    
    if args.fill_missing:
        processor.fill_missing(method=args.fill_missing, value=args.fill_value)
    
    if args.sort:
        processor.sort_data(args.sort, ascending=not args.descending)
    
    # Save result
    if not processor.save_file(args.output):
        sys.exit(1)
    
    # Show summary
    processor.show_summary()
    
    logger.info("✓ Processing completed successfully")


if __name__ == "__main__":
    main()
