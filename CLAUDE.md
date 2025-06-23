# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains enterprise-grade shell scripts for managing MySQL databases through a professional command-line interface. The main focus is on the **mysql_db_management_mac_os_laravel-herd.sh** script which has been enhanced to enterprise standards with advanced logging, error handling, and user experience.

## Script Variants

There are three script variants, each tailored for different environments:

1. **mysql_db_management.sh**: Generic Linux/Unix version with empty credentials
2. **mysql_db_management_mac.sh**: macOS-optimized with terminal compatibility fixes  
3. **mysql_db_management_mac_os_laravel-herd.sh**: **Enterprise Edition** - Laravel Herd specific with full enterprise features

## Enterprise Edition Features (Laravel Herd Script)

### Application Structure
The enterprise script creates an organized directory structure in the user's home directory:
```
~/.mysql-db-manager/
├── config/
│   └── settings.conf              # Application configuration
├── logs/
│   ├── mysql-db-manager.log       # Main application log
│   ├── sessions/                  # Session-specific logs
│   │   └── session_YYYYMMDD_PID.log
│   ├── operations/                # Database operation logs
│   │   └── operations_YYYYMMDD.log
│   └── errors/                    # Error-specific logs
│       └── errors_YYYYMMDD.log
└── backups/                       # Automatic database backups
    └── database_backup_YYYYMMDD_HHMMSS.sql
```

### Commands

#### Running the enterprise script
```bash
# Make executable
chmod +x mysql_db_management_mac_os_laravel-herd.sh

# Run the enterprise script
./mysql_db_management_mac_os_laravel-herd.sh
```

#### Configuration management
```bash
# Configuration is stored at ~/.mysql-db-manager/config/settings.conf
# Settings are automatically loaded and can be modified through the UI
```

#### Viewing logs
```bash
# Main application log
tail -f ~/.mysql-db-manager/logs/mysql-db-manager.log

# Current session log
tail -f ~/.mysql-db-manager/logs/sessions/session_$(date +%Y%m%d)_$$.log

# Operation logs
ls ~/.mysql-db-manager/logs/operations/
```

## Enterprise Architecture

### Core Enterprise Functions

1. **setup_environment()**: Creates organized directory structure and loads configuration
2. **validate_mysql_connection()**: Robust connection testing with retry logic
3. **create_database_backup()**: Automatic backup creation before destructive operations
4. **drop_all_tables_forcefully()**: Safe table removal with verification
5. **import_sql_file()**: Advanced SQL import with progress tracking and validation
6. **log_operation()**: Comprehensive operation logging

### Enhanced UI System
- **show_header()**: Professional box-drawn interface
- **show_progress_bar()**: Real-time progress indicators  
- **prompt_selection()**: Table-formatted menu system
- **confirm_action()**: Risk-aware confirmation dialogs

### Main Application Flow
1. **Initialization**: Set session variables, create directory structure
2. **Environment Setup**: Load configuration, validate MySQL connection
3. **Main Menu**: Professional UI with database statistics, configuration, logs
4. **Operation Execution**: Enhanced database operations with safety features
5. **Cleanup**: Session logging, cleanup, and exit

### Enterprise Variables

#### Core Configuration
- `APP_HOME`: Application directory (~/.mysql-db-manager)
- `CONFIG_FILE`: Configuration file location
- `LOG_DIR`, `SESSION_LOG`, `OPERATION_LOG`, `ERROR_LOG`: Logging directories
- `BACKUP_DIR`: Automatic backup location
- `SESSION_ID`: Unique session identifier
- `BACKUP_ENABLED`: Toggle for automatic backups

#### Database Connection
- `DB_USER`, `DB_PASS`, `DB_HOST`, `DB_PORT`: Connection parameters
- `MYSQL_CMD`: Validated MySQL binary path
- `MAX_RETRIES`: Connection retry attempts

### Enterprise Safety Features
- **Session Management**: Unique session tracking with PID-based locking
- **Comprehensive Logging**: Multi-level logging (session, operation, error)
- **Automatic Backups**: Pre-operation database backups with verification
- **Risk Assessment**: High/medium/low risk operation classification
- **Error Recovery**: Detailed error codes with remediation suggestions
- **Input Validation**: SQL file validation and sanity checks

### Professional UI Features
- **Color-coded Messages**: Success (✓), Error (✗), Warning (⚠), Info (ℹ), Processing (⚡)
- **Table Formatting**: Box-drawn borders and organized data display
- **Progress Tracking**: Real-time progress bars for long operations
- **Menu Navigation**: Professional table-based selection system
- **Statistics Display**: Database information with table counts and sizes

## Development Guidelines

### Enterprise Script Maintenance:
1. **Always test** database operations in a development environment first
2. **Preserve logging structure** - maintain the organized log directory hierarchy
3. **Follow error handling patterns** - use proper error codes and recovery mechanisms
4. **Maintain UI consistency** - use established color schemes and formatting
5. **Preserve session tracking** - ensure SESSION_ID and session logs are maintained

### Configuration Management:
- Configuration is auto-generated and stored in `~/.mysql-db-manager/config/settings.conf`
- Environment variables take precedence over configuration file values
- Use `save_configuration()` function when updating settings programmatically

### Logging Best Practices:
- Use appropriate log levels: `log_success`, `log_error`, `log_warning`, `log_info`, `log_operation`
- Operation logs are automatically created for database operations
- Error logs capture all errors for debugging
- Session logs track individual script executions

### Common Enterprise Modifications:
- **Adding new operations**: Extend the main menu and add corresponding task functions
- **Modifying backup behavior**: Update `create_database_backup()` and `BACKUP_ENABLED` logic
- **Changing log retention**: Modify log cleanup in `show_logs_menu()`
- **Adding new configuration options**: Update `save_configuration()` and `setup_environment()`

### Original Functionality Preserved:
All original core functionality remains intact:
- ✅ Clear database (drop all tables)
- ✅ Import SQL files from Downloads
- ✅ Combined clear and import operations
- ✅ SQL file renaming for compatibility
- ✅ Database selection menus
- ✅ Progress indicators
- ✅ Laravel Herd compatibility

### Testing:
- The enterprise script maintains full backward compatibility
- All original menu options and functionality are preserved
- Enhanced with enterprise features while keeping the core workflow intact