# MySQL DB Management Shell Script

## Overview
This script is designed to manage MySQL databases by providing functionalities to clear all tables in a specified database and to import SQL files into a database. It includes a user-friendly menu for selecting databases and SQL files, and it supports the renaming of SQL files to a standardized format.

## Features
- **Clear Database**: Drops all tables from a specified MySQL database.
- **Import SQL File**: Imports a selected SQL file into a specified MySQL database.
- **Both**: Combines clearing a database and then importing an SQL file into it.
- **Progress Bar**: Displays a progress bar for long-running operations.
- **Logging**: Provides colored and timestamped log messages for better visibility.

## Requirements
- MySQL client must be installed and configured.
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
- **MySQL Client**: Ensure that the MySQL client is installed on your system and properly configured.
  ```bash
  sudo apt-get install mysql-client
  ```
- **Database Access**: Make sure you have the necessary permissions to access and modify the databases.
- **Directory Access**: The script assumes that SQL files are located in the `Downloads` directory of the user's home folder.

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
