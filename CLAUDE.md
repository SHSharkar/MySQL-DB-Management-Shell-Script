# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository contains MySQL database management shell scripts for clearing database tables and importing SQL files. The scripts provide interactive menus with progress bars, logging, and safety confirmations for destructive operations.

## Script Variants

- **mysql_db_management.sh**: Basic version requiring manual DB_USER/DB_PASS configuration (334 lines)
- **mysql_db_management_mac.sh**: macOS version with automatic MySQL client detection (341 lines)
- **mysql_db_management_mac_os_laravel-herd.sh**: Enhanced Laravel Herd compatibility version with timing and improved UX (522 lines)

## Key Configuration

All scripts require these variables to be set:
```bash
DB_USER="your_username"     # MySQL username
DB_PASS="your_password"     # MySQL password  
DB_HOST="127.0.0.1"        # Database host (mac versions)
DB_PORT="3306"             # Database port (mac versions)
DOWNLOADS_PATH="$HOME/Downloads"  # SQL files location
```

## Core Functionality

The scripts provide three main operations:
1. **Clear Database**: Drop all tables from selected database (excludes system DBs)
2. **Import SQL File**: Import SQL from Downloads directory into selected database  
3. **Both**: Clear database then import SQL file

## Architecture

### Safety Features
- Excludes system databases: 'information_schema', 'mysql', 'performance_schema', 'sys', 'ploi', 'phpmyadmin'
- Forces foreign key checks off during table drops
- Confirms destructive actions before execution
- Checks for existing data before imports

### User Interface
- Interactive select menus with numbered options
- Colored logging with timestamps
- Progress bars for long operations
- Graceful navigation (Main Menu, Go Back, Quit options)

### File Handling
- Auto-renames SQL files to slug format (removes special characters)
- Lists available SQL files from Downloads directory
- Validates file existence before operations
- **Enhanced version adds**: File size display, formatted file listing with sizes

## Testing

To test the scripts:
```bash
# Make executable
chmod +x mysql_db_management.sh

# Run with proper DB credentials configured
./mysql_db_management.sh
```

## Enhanced Features (Laravel Herd Version)

The Laravel Herd version includes significant improvements over the basic versions:

### New Functions Added
- `show_header()`: Displays formatted header with database connection info and timestamps
- `show_action_header()`: Shows section headers with decorative borders  
- `list_sql_files_with_sizes()`: Lists SQL files with their sizes for better selection
- `format_file_size()`: Converts bytes to human-readable format (B, K, M, G)
- `format_duration()`: Formats operation duration in hours/minutes/seconds
- `get_timestamp()`: Gets Unix timestamp for timing operations

### Enhanced User Interface
- Professional bordered headers with system info
- File size display during SQL file selection
- Real-time operation timing and duration reporting
- Enhanced confirmation prompts using specific keywords:
  - "YES" for database clearing
  - "OVERRIDE" for importing into non-empty databases
  - "PROCEED" for combined operations
- Visual indicators: ✓ for success, ⚠ for warnings
- Step-by-step operation progress (Step 1/2, Step 2/2)

### Improved Functionality
- Better error handling with contextual messages
- Operation start/end time display
- Progress dots during import operations
- Enhanced menu navigation with clearer options
- More robust selection mechanism with input validation

### Technical Implementation
- Uses Unicode symbols for better visual feedback
- Implements proper error handling with PIPESTATUS
- Improved MySQL command execution with better output parsing
- Enhanced confirmation workflow prevents accidental operations

## Security Considerations

- Scripts handle database credentials in plaintext variables
- Operations are destructive (DROP TABLE) - use with extreme caution
- No backup functionality - users must backup before running
- Designed for development environments, not production use
- Enhanced version adds stronger confirmation mechanisms to prevent accidents