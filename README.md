# MySQL & PostgreSQL DB Management Shell Scripts

## Overview
These scripts are designed to manage MySQL and PostgreSQL databases by providing functionalities to clear all tables in a specified database and to import SQL files into a database. They include user-friendly menus for selecting databases and SQL files, and support the renaming of SQL files to a standardized format. Both MySQL and PostgreSQL variants offer identical professional interfaces and functionality.

## Features
- **Clear Database**: Drops all tables from a specified MySQL or PostgreSQL database.
- **Import SQL File**: Imports a selected SQL file into a specified MySQL or PostgreSQL database.
- **Both**: Combines clearing a database and then importing an SQL file into it.
- **Multi-Database Support**: Separate scripts for MySQL and PostgreSQL with database-specific optimizations.
- **Progress Bar**: Displays a progress bar for long-running operations.
- **Logging**: Provides colored and timestamped log messages for better visibility.

### Enhanced Features (Laravel Herd Version)
- **Professional UI**: Formatted headers with borders, database connection info, and timestamps
- **File Size Display**: Shows SQL file sizes during selection for better decision making
- **Operation Timing**: Tracks and reports duration for all database operations
- **Enhanced Safety Confirmations**: Uses specific confirmation words (YES/OVERRIDE/PROCEED) to prevent accidental operations
- **Visual Progress Indicators**: Uses checkmarks (✓) and warning symbols (⚠) for clear status feedback
- **Real-time Feedback**: Displays operation start/end times and progress dots during imports
- **Step-by-Step Operations**: Clear indication of multi-step processes (Step 1/2, Step 2/2)
- **Improved Error Handling**: Better error messages and graceful failure handling

## Requirements
- **For MySQL scripts**: MySQL client must be installed and configured.
- **For PostgreSQL scripts**: PostgreSQL client (`psql`) must be installed and configured.
- Proper database access credentials (username and password).
- Access to the `Downloads` directory for storing and renaming SQL files.
- Bash environment to execute the script.

## Setup and Usage
1. **Clone the Repository**:
   - Using HTTPS:
     ```bash
     git clone https://github.com/SHSharkar/MySQL-DB-Management-Shell-Script.git && cd MySQL-DB-Management-Shell-Script
     ```
   - Using SSH:
     ```bash
     git clone git@github.com:SHSharkar/MySQL-DB-Management-Shell-Script.git && cd MySQL-DB-Management-Shell-Script
     ```

2. **Configure the Script**:
   Edit the script to set the MySQL username and password:
   ```bash
   DB_USER="your_username"
   DB_PASS="your_password"
   ```

3. **Run the Script**:
   Make the script executable and then run it:
   ```bash
   chmod +x mysql_db_management.sh
   ./mysql_db_management.sh
   ```

   **For macOS users with Laravel Herd**, use the enhanced version:
   ```bash
   # MySQL version
   chmod +x mysql_db_management_mac_os_laravel-herd.sh
   ./mysql_db_management_mac_os_laravel-herd.sh
   
   # PostgreSQL version
   chmod +x pgsql_db_management_mac_os_laravel-herd.sh
   ./pgsql_db_management_mac_os_laravel-herd.sh
   ```

4. **Main Menu Options**:
   - **Clear Database**: Lists available databases (excluding system databases) and allows you to select one to clear all tables.
   - **Import SQL File**: Lists available SQL files in the `Downloads` directory and imports the selected file into a specified database.
   - **Both**: Clears all tables in a specified database and then imports a selected SQL file into it.
   - **Quit**: Exits the script.

## Step-by-Step Information
### Clear Database
- Lists all non-system databases.
- Prompts the user to select a database.
- Confirms the action before proceeding.
- Drops all tables in the selected database.

### Import SQL File
- Renames all SQL files in the `Downloads` directory to a slug format.
- Lists all renamed SQL files.
- Prompts the user to select an SQL file and a target database.
- Imports the selected SQL file into the specified database.

### Both
- Combines the clear database and import SQL file functionalities.
- First, clears all tables in the specified database.
- Then, imports the selected SQL file into the same database.

## Requirements and Prerequisites
- **Database Clients**: Ensure that the appropriate database client is installed on your system and properly configured.
  ```bash
  # MySQL Client
  # Linux/Ubuntu
  sudo apt-get install mysql-client
  
  # macOS with Homebrew
  brew install mysql-client
  
  # PostgreSQL Client
  # Linux/Ubuntu
  sudo apt-get install postgresql-client
  
  # macOS with Homebrew
  brew install postgresql
  
  # Laravel Herd (includes both MySQL and PostgreSQL)
  ```
- **Database Access**: Make sure you have the necessary permissions to access and modify the databases.
- **Directory Access**: The script assumes that SQL files are located in the `Downloads` directory of the user's home folder.

### Version-Specific Requirements
- **Basic Version**: Manual configuration of database credentials
- **macOS Version**: Automatic MySQL client detection and validation  
- **Laravel Herd Version**: Enhanced UI requires terminal with Unicode support for symbols (✓, ⚠)

## Script Versions

### MySQL Scripts

#### 1. mysql_db_management.sh (Basic Version - 334 lines)
- Simple interactive menu system
- Manual database credential configuration
- Basic progress indicators and logging

#### 2. mysql_db_management_mac.sh (macOS Version - 341 lines)  
- Automatic MySQL client detection
- Enhanced compatibility with macOS systems
- Improved error handling for missing MySQL client

#### 3. mysql_db_management_mac_os_laravel-herd.sh (Enhanced Version - 522 lines)
- Professional UI with formatted headers and borders
- Real-time operation timing and duration reporting
- File size display during SQL file selection
- Enhanced safety confirmations with specific keywords
- Visual progress indicators with Unicode symbols
- Step-by-step operation feedback
- Improved error messages and user experience

### PostgreSQL Scripts

#### 4. pgsql_db_management_mac_os_laravel-herd.sh (PostgreSQL Enhanced Version - 522 lines)
- **Complete PostgreSQL Implementation**: Full feature parity with MySQL enhanced version
- **Database-Specific Adaptations**: Uses `psql` with `PGPASSWORD` authentication
- **PostgreSQL System Integration**: Queries `pg_database` and `pg_tables` catalogs
- **CASCADE Operations**: Implements `DROP TABLE CASCADE` for foreign key constraints
- **Extended File Support**: Supports `.sql`, `.dump`, and `.psql` file formats
- **Professional Interface**: Identical UI/UX to MySQL version with PostgreSQL branding
- **Laravel Herd Compatible**: Default port 5432, works with Herd PostgreSQL setup

## Caution
**Warning**: This script will alter database tables. It is strongly advised to use it with caution, especially on production databases. Ensure you have proper backups before running the script.

## Contributing
This is an open-source project, and contributions are welcome. Feel free to open issues or submit pull requests with improvements or fixes.

### How to Contribute
1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Make your changes and test thoroughly.
4. Submit a pull request with a clear description of your changes.

### License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

### Contact
For any issues or suggestions, please open an issue on the GitHub repository or contact the maintainer.
