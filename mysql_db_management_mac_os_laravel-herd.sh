#!/bin/bash

DB_USER="root"
DB_PASS=""
DB_HOST="127.0.0.1"
DB_PORT="3306"
DOWNLOADS_PATH="$HOME/Downloads"

RED='\033[0;31m'
GREEN='\033[0;32m'
DARK_YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - ${BOLD}$1${NC}"
}

show_progress() {
    local current=$1
    local total=$2
    local progress=$((current * 100 / total))
    local width=50
    local filled=$((progress * width / 100))
    local empty=$((width - filled))

    echo -ne "["
    for ((i = 0; i < filled; i++)); do echo -ne "#"; done
    for ((i = 0; i < empty; i++)); do echo -ne " "; done
    echo -ne "] $progress%\\r"
}

# Set MYSQL_CMD to the path of the mysql command
MYSQL_CMD="$(command -v mysql)"
if [ -z "$MYSQL_CMD" ]; then
    log "${RED}mysql command not found. Please install MySQL client or ensure it is in your PATH.${NC}"
    exit 1
else
    log "${GREEN}Using MySQL command at: $MYSQL_CMD${NC}"
fi

list_databases() {
    local system_dbs="'information_schema', 'mysql', 'performance_schema', 'sys', 'ploi', 'phpmyadmin'"
    "$MYSQL_CMD" -u"$DB_USER" --password="$DB_PASS" -h"$DB_HOST" -P"$DB_PORT" -e "SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT IN ($system_dbs);" -sN 2>/dev/null
}

check_if_database_contains_tables() {
    local db_name=$1
    local tables=$("$MYSQL_CMD" -u"$DB_USER" --password="$DB_PASS" -h"$DB_HOST" -P"$DB_PORT" -D"$db_name" -e 'SHOW TABLES;' | awk '{print $1}' | grep -v '^Tables_in_')
    if [ -z "$tables" ]; then
        return 1
    else
        return 0
    fi
}

drop_all_tables_forcefully() {
    local db_name=$1
    local tables=$("$MYSQL_CMD" -u"$DB_USER" --password="$DB_PASS" -h"$DB_HOST" -P"$DB_PORT" -D"$db_name" -e 'SHOW FULL TABLES WHERE Table_Type = "BASE TABLE";' | awk '{print $1}' | grep -v '^Tables')

    if [ -z "$tables" ]; then
        log "${DARK_YELLOW}No tables to drop in database $db_name.${NC}"
        return 0
    fi

    local total_tables=$(echo "$tables" | wc -l)
    local current_table=0

    local drop_tables_sql="SET FOREIGN_KEY_CHECKS = 0; "
    for table in $tables; do
        drop_tables_sql+="DROP TABLE IF EXISTS \`$table\`; "
        ((current_table++))
        show_progress $current_table $total_tables
        sleep 0.1
    done
    drop_tables_sql+="SET FOREIGN_KEY_CHECKS = 1;"

    echo -ne "\n"
    log "${DARK_YELLOW}Forcefully dropping all tables in the database $db_name...${NC}"
    "$MYSQL_CMD" -u"$DB_USER" --password="$DB_PASS" -h"$DB_HOST" -P"$DB_PORT" -D"$db_name" -e "$drop_tables_sql"

    local remaining_tables=$("$MYSQL_CMD" -u"$DB_USER" --password="$DB_PASS" -h"$DB_HOST" -P"$DB_PORT" -D"$db_name" -e 'SHOW TABLES;' | awk '{ print $1}' | grep -v '^Tables_in_')
    if [ -z "$remaining_tables" ]; then
        log "${GREEN}All tables have been successfully removed from the database $db_name.${NC}"
        return 0
    else
        log "${RED}There are still tables remaining in the database $db_name:${NC}"
        echo "$remaining_tables"
        return 1
    fi
}

rename_sql_files() {
    local path="$1"
    cd "$path"
    for file in *.sql; do
        [ -e "$file" ] || continue
        local new_name=$(echo "$file" | sed -e 's/[^A-Za-z0-9._-]/_/g' -e 's/__*/_/g')
        if [ "$file" != "$new_name" ]; then
            mv -v "$file" "$new_name"
        fi
    done
    cd - >/dev/null
}

list_sql_files() {
    local path="$1"
    find "$path" -maxdepth 1 -type f -name "*.sql" -exec basename {} \;
}

import_sql_file() {
    local db_name="$1"
    local sql_file="$2"

    log "${DARK_YELLOW}Importing $sql_file into database $db_name...${NC}"
    for i in $(seq 1 50); do
        show_progress $i 50
        sleep 0.1
    done
    echo -ne "\n"
    "$MYSQL_CMD" -u"$DB_USER" --password="$DB_PASS" -h"$DB_HOST" -P"$DB_PORT" "$db_name" <"$DOWNLOADS_PATH/$sql_file"
    if [ $? -eq 0 ]; then
        log "${GREEN}Import completed successfully.${NC}"
    else
        log "${RED}Import failed. Please check the error messages above.${NC}"
    fi
}

prompt_selection() {
    local prompt_message="$1"
    shift
    local options=("$@")
    options+=("Main Menu" "Quit")

    PS3="$prompt_message"$'\n'
    select opt in "${options[@]}"; do
        if [[ "$opt" == "Quit" ]]; then
            log "${DARK_YELLOW}User chose to quit. Exiting.${NC}"
            exit 0
        elif [[ "$opt" == "Main Menu" ]]; then
            return 1
        elif [[ -n "$opt" ]]; then
            REPLY=$((REPLY - 1))
            return 0
        else
            echo "${RED}Invalid selection. Please try again.${NC}"
        fi
    done
}

confirm_action() {
    local action="$1"
    local target="$2"
    echo -e "${DARK_YELLOW}You have selected to ${BOLD}$action${NC}${DARK_YELLOW}: $target${NC}"
    PS3="Confirm or Go Back: "$'\n'
    select yn in "Confirm" "Go Back"; do
        case $yn in
        Confirm) return 0 ;;
        "Go Back") return 1 ;;
        esac
    done
}

clear_database_task() {
    while true; do
        log "${BLUE}Available databases (excluding system databases):${NC}"
        databases=()
        while IFS= read -r line; do
            databases+=("$line")
        done < <(list_databases)

        if [ ${#databases[@]} -eq 0 ]; then
            log "${RED}No databases found.${NC}"
            return
        fi

        # Debugging line to print database names
        log "Databases found: ${databases[@]}"

        if ! prompt_selection "Select the number corresponding to the database you want to clean:" "${databases[@]}"; then
            return
        fi
        db_name="${databases[$REPLY]}"
        if confirm_action "clean the database" "$db_name"; then
            log "${BLUE}You have confirmed the action.${NC}"
            drop_all_tables_forcefully "$db_name"
        else
            log "${DARK_YELLOW}Action cancelled. Returning to previous menu.${NC}"
            continue
        fi
        PS3="Would you like to clean another database, return to the main menu, or quit? "$'\n'
        select opt in "Clean another" "Main Menu" "Quit"; do
            case $opt in
            "Clean another") break ;;
            "Main Menu") return ;;
            "Quit")
                log "${DARK_YELLOW}Operation completed. Exiting.${NC}"
                exit 0
                ;;
            *)
                echo "${RED}Invalid selection. Please try again.${NC}"
                ;;
            esac
        done
    done
}

import_sql_file_task() {
    rename_sql_files "$DOWNLOADS_PATH"
    sql_files=()
    while IFS= read -r line; do
        sql_files+=("$line")
    done < <(list_sql_files "$DOWNLOADS_PATH")
    if [ ${#sql_files[@]} -eq 0 ]; then
        log "${RED}No SQL files found in $DOWNLOADS_PATH.${NC}"
        exit 1
    fi

    while true; do
        if ! prompt_selection "Please select an SQL file to import:" "${sql_files[@]}"; then
            return
        fi
        sql_file="${sql_files[$REPLY]}"
        log "${DARK_YELLOW}You have selected the SQL file: $sql_file${NC}"

        log "${BLUE}Available databases (excluding system databases):${NC}"
        databases=()
        while IFS= read -r line; do
            databases+=("$line")
        done < <(list_databases)

        if [ ${#databases[@]} -eq 0 ]; then
            log "${RED}No databases found.${NC}"
            return
        fi

        # Debugging line to print database names
        log "Databases found: ${databases[@]}"

        if ! prompt_selection "Please select the target database:" "${databases[@]}"; then
            return
        fi
        db_name="${databases[$REPLY]}"
        if check_if_database_contains_tables "$db_name"; then
            log "${RED}The database $db_name already contains data.${NC}"
            if ! confirm_action "import the SQL file into the database (this may cause conflicts)" "$db_name"; then
                log "${DARK_YELLOW}Action cancelled. Returning to previous menu.${NC}"
                continue
            fi
        else
            if ! confirm_action "import the SQL file into the database" "$db_name"; then
                log "${DARK_YELLOW}Action cancelled. Returning to previous menu.${NC}"
                continue
            fi
        fi
        import_sql_file "$db_name" "$sql_file"
        log "${GREEN}Task completed. Returning to the main menu.${NC}"
        break
    done
}

both_tasks() {
    log "${BLUE}Available databases (excluding system databases):${NC}"
    databases=()
    while IFS= read -r line; do
        databases+=("$line")
    done < <(list_databases)

    if [ ${#databases[@]} -eq 0 ]; then
        log "${RED}No databases found.${NC}"
        return
    fi

    # Debugging line to print database names
    log "Databases found: ${databases[@]}"

    while true; do
        if ! prompt_selection "Select the number corresponding to the database you want to clean:" "${databases[@]}"; then
            return
        fi
        db_name="${databases[$REPLY]}"
        if confirm_action "clean and import into the database" "$db_name"; then
            log "${BLUE}You have confirmed the action.${NC}"
            drop_all_tables_forcefully "$db_name"

            rename_sql_files "$DOWNLOADS_PATH"
            sql_files=()
            while IFS= read -r line; do
                sql_files+=("$line")
            done < <(list_sql_files "$DOWNLOADS_PATH")
            if [ ${#sql_files[@]} -eq 0 ]; then
                log "${RED}No SQL files found in $DOWNLOADS_PATH.${NC}"
                exit 1
            fi

            if ! prompt_selection "Please select an SQL file to import:" "${sql_files[@]}"; then
                return
            fi
            sql_file="${sql_files[$REPLY]}"
            import_sql_file "$db_name" "$sql_file"
        else
            log "${DARK_YELLOW}Action cancelled. Returning to previous menu.${NC}"
            continue
        fi
        prompt_next_action
        break
    done
}

prompt_next_action() {
    PS3="Would you like to perform another action, return to the main menu, or quit? "$'\n'
    options=("Clear Database" "Import SQL File" "Both" "Main Menu" "Quit")
    select opt in "${options[@]}"; do
        case $opt in
        "Clear Database")
            clear_database_task
            ;;
        "Import SQL File")
            import_sql_file_task
            ;;
        "Both")
            both_tasks
            ;;
        "Main Menu")
            return
            ;;
        "Quit")
            log "${DARK_YELLOW}Operation completed. Exiting.${NC}"
            exit 0
            ;;
        *)
            echo "${RED}Invalid selection. Please try again.${NC}"
            ;;
        esac
    done
}

main_menu() {
    PS3="Please select an action: "$'\n'
    options=("Clear Database" "Import SQL File" "Both" "Quit")
    select action in "${options[@]}"; do
        case $action in
        "Clear Database")
            clear_database_task
            ;;
        "Import SQL File")
            import_sql_file_task
            ;;
        "Both")
            both_tasks
            ;;
        "Quit")
            log "${DARK_YELLOW}User chose to quit. Exiting.${NC}"
            exit 0
            ;;
        *)
            echo "${RED}Invalid selection. Please try again.${NC}"
            ;;
        esac
        return
    done
}

log "${BLUE}Starting database management script...${NC}"

while true; do
    clear
    main_menu
done
