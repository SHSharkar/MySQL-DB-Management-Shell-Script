#!/bin/bash

DB_USER="root"
DB_PASS=""
DB_HOST="127.0.0.1"
DB_PORT="5432"
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

# Set PSQL_CMD to the path of the psql command
PSQL_CMD="$(command -v psql)"
if [ -z "$PSQL_CMD" ]; then
    log "${RED}psql command not found. Please install PostgreSQL client or ensure it is in your PATH.${NC}"
    exit 1
else
    log "${GREEN}Using PostgreSQL command at: $PSQL_CMD${NC}"
fi

list_databases() {
    local system_dbs="'template0', 'template1', 'postgres'"
    PGPASSWORD="$DB_PASS" "$PSQL_CMD" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "postgres" -t -c "SELECT datname FROM pg_database WHERE datname NOT IN ($system_dbs) AND datistemplate = false;" 2>/dev/null | sed 's/^ *//;s/ *$//' | grep -v '^$'
}

list_tables() {
    local db_name=$1
    PGPASSWORD="$DB_PASS" "$PSQL_CMD" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db_name" -t -c "SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;" 2>/dev/null | sed 's/^ *//;s/ *$//' | grep -v '^$'
}

format_export_filename() {
    local db_name=$1
    local table_name=$2
    local date_suffix=$(date "+%Y_%m_%d_%H%M%S")
    local base_name="${db_name}_${table_name}_${date_suffix}"
    echo "$base_name" | sed -e 's/[^A-Za-z0-9._-]/_/g' -e 's/__*/_/g'
}

export_full_database() {
    local db_name=$1
    local date_suffix=$(date "+%Y_%m_%d_%H%M%S")
    local export_filename="${db_name}_full_backup_${date_suffix}"
    export_filename=$(echo "$export_filename" | sed -e 's/[^A-Za-z0-9._-]/_/g' -e 's/__*/_/g')
    local export_path="$DOWNLOADS_PATH/${export_filename}.sql"
    
    echo -e "\n${BLUE}▶ Starting full database export...${NC}"
    local start_time=$(get_timestamp)
    echo -e "${BLUE}Started at: $(date "+%I:%M:%S %p")${NC}"
    
    PGPASSWORD="$DB_PASS" pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db_name" --clean --if-exists --no-owner --no-acl > "$export_path" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        local end_time=$(get_timestamp)
        local duration=$((end_time - start_time))
        local file_size=$(ls -lh "$export_path" | awk '{print $5}')
        
        echo -e "\n${GREEN}✓ Full database export completed successfully${NC}"
        echo -e "${GREEN}✓ File: ${export_filename}.sql (${file_size})${NC}"
        echo -e "${GREEN}✓ Location: $DOWNLOADS_PATH${NC}"
        echo -e "${GREEN}✓ Duration: $(format_duration $duration)${NC}"
        echo -e "${GREEN}✓ Finished at: $(date "+%I:%M:%S %p")${NC}"
        return 0
    else
        echo -e "\n${RED}✗ Full database export failed${NC}"
        rm -f "$export_path"
        return 1
    fi
}

check_if_database_contains_tables() {
    local db_name=$1
    local tables=$(PGPASSWORD="$DB_PASS" "$PSQL_CMD" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db_name" -t -c "SELECT tablename FROM pg_tables WHERE schemaname = 'public';" 2>/dev/null | sed 's/^ *//;s/ *$//' | grep -v '^$')
    if [ -z "$tables" ]; then
        return 1
    else
        return 0
    fi
}

drop_all_tables_forcefully() {
    local db_name=$1
    local start_time=$(get_timestamp)
    local tables=$(PGPASSWORD="$DB_PASS" "$PSQL_CMD" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db_name" -t -c "SELECT tablename FROM pg_tables WHERE schemaname = 'public';" 2>/dev/null | sed 's/^ *//;s/ *$//' | grep -v '^$')

    if [ -z "$tables" ]; then
        log "${DARK_YELLOW}No tables to drop in database $db_name.${NC}"
        return 0
    fi

    local total_tables=$(echo "$tables" | wc -l)
    local current_table=0

    echo -e "${BLUE}Found ${total_tables} table(s) to remove${NC}"
    
    # PostgreSQL approach: Drop tables individually with CASCADE
    local drop_commands=""
    for table in $tables; do
        drop_commands+="DROP TABLE IF EXISTS \"$table\" CASCADE; "
        ((current_table++))
        show_progress $current_table $total_tables
        sleep 0.05
    done

    echo -ne "\n"
    log "${DARK_YELLOW}Executing drop operation...${NC}"
    PGPASSWORD="$DB_PASS" "$PSQL_CMD" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db_name" -c "$drop_commands" >/dev/null 2>&1

    local end_time=$(get_timestamp)
    local duration=$((end_time - start_time))
    
    local remaining_tables=$(PGPASSWORD="$DB_PASS" "$PSQL_CMD" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db_name" -t -c "SELECT tablename FROM pg_tables WHERE schemaname = 'public';" 2>/dev/null | sed 's/^ *//;s/ *$//' | grep -v '^$')
    if [ -z "$remaining_tables" ]; then
        echo -e "${GREEN}✓ All tables successfully removed from $db_name${NC}"
        echo -e "${GREEN}✓ Operation completed in: $(format_duration $duration)${NC}"
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
    for file in *.sql *.dump *.psql; do
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
    find "$path" -maxdepth 1 -type f \( -name "*.sql" -o -name "*.dump" -o -name "*.psql" \) -exec basename {} \;
}

list_sql_files_with_sizes() {
    local path="$1"
    for file in "$path"/*.sql "$path"/*.dump "$path"/*.psql; do
        if [ -f "$file" ]; then
            local basename=$(basename "$file")
            local size=$(ls -lh "$file" | awk '{print $5}')
            echo "${basename}|${size}"
        fi
    done
}

format_file_size() {
    local bytes=$1
    if [ $bytes -ge 1073741824 ]; then
        echo "$(echo "scale=2; $bytes/1073741824" | bc)G"
    elif [ $bytes -ge 1048576 ]; then
        echo "$(echo "scale=2; $bytes/1048576" | bc)M"
    elif [ $bytes -ge 1024 ]; then
        echo "$(echo "scale=2; $bytes/1024" | bc)K"
    else
        echo "${bytes}B"
    fi
}

import_sql_file() {
    local db_name="$1"
    local sql_file="$2"
    local start_time=$(get_timestamp)
    local file_size=$(ls -lh "$DOWNLOADS_PATH/$sql_file" | awk '{print $5}')

    echo -e "${DARK_YELLOW}Importing $sql_file (${file_size}) into database $db_name...${NC}"
    echo -e "${BLUE}Started at: $(date "+%I:%M:%S %p")${NC}"
    
    # Use psql to import the file
    PGPASSWORD="$DB_PASS" "$PSQL_CMD" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db_name" -f "$DOWNLOADS_PATH/$sql_file" 2>&1 | while IFS= read -r line; do
        echo -ne "${BLUE}.${NC}"
    done
    
    local import_result=${PIPESTATUS[0]}
    local end_time=$(get_timestamp)
    local duration=$((end_time - start_time))
    
    echo ""
    if [ $import_result -eq 0 ]; then
        echo -e "${GREEN}✓ Import completed successfully${NC}"
        echo -e "${GREEN}✓ Duration: $(format_duration $duration)${NC}"
        echo -e "${GREEN}✓ Finished at: $(date "+%I:%M:%S %p")${NC}"
    else
        echo -e "${RED}✗ Import failed${NC}"
        echo -e "${RED}Duration: $(format_duration $duration)${NC}"
    fi
}

prompt_selection() {
    local prompt_message="$1"
    shift
    local options=("$@")
    
    echo -e "${BLUE}$prompt_message${NC}"
    echo ""
    local max_width=0
    for opt in "${options[@]}"; do
        local clean_opt=$(echo "$opt" | sed 's/\[[^]]*\]$//')
        local len=${#clean_opt}
        [[ $len -gt $max_width ]] && max_width=$len
    done
    
    for i in "${!options[@]}"; do
        local display_opt="${options[$i]}"
        if [[ "$display_opt" =~ ^(.*)\[([^\[]*)\]$ ]]; then
            local name="${BASH_REMATCH[1]}"
            local size="${BASH_REMATCH[2]}"
            printf "  ${GREEN}%-3s${NC} %-${max_width}s ${DARK_YELLOW}[%s]${NC}\n" "$((i+1))." "${name% }" "$size"
        else
            printf "  ${GREEN}%-3s${NC} %-${max_width}s\n" "$((i+1))." "$display_opt"
        fi
    done
    printf "  ${GREEN}%-3s${NC} %-${max_width}s\n" "$((${#options[@]}+1))." "Return to Main Menu"
    printf "  ${GREEN}%-3s${NC} %-${max_width}s\n" "$((${#options[@]}+2))." "Exit"
    echo ""
    
    while true; do
        echo -ne "${BOLD}Enter your choice [1-$((${#options[@]}+2))]: ${NC}"
        read -r choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]]; then
            if [[ $choice -eq $((${#options[@]}+2)) ]]; then
                echo -e "\n${GREEN}Thank you for using PostgreSQL Database Management System${NC}"
                exit 0
            elif [[ $choice -eq $((${#options[@]}+1)) ]]; then
                return 1
            elif [[ $choice -ge 1 && $choice -le ${#options[@]} ]]; then
                REPLY=$((choice - 1))
                return 0
            fi
        fi
        echo -e "${RED}Invalid selection. Please try again.${NC}"
    done
}

show_header() {
    clear
    local current_date=$(date "+%A, %B %d, %Y")
    local current_time=$(date "+%I:%M:%S %p")
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}       ${BOLD}PostgreSQL Database Management System${NC}                  ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}         Connected to: ${GREEN}$DB_HOST:$DB_PORT${NC}                      ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}         ${current_date} - ${current_time}              ${BLUE}║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

format_duration() {
    local duration=$1
    local hours=$((duration / 3600))
    local minutes=$(( (duration % 3600) / 60 ))
    local seconds=$((duration % 60))
    
    if [[ $hours -gt 0 ]]; then
        printf "%dh %dm %ds" $hours $minutes $seconds
    elif [[ $minutes -gt 0 ]]; then
        printf "%dm %ds" $minutes $seconds
    else
        printf "%d.%03ds" $seconds $((duration % 1000))
    fi
}

get_timestamp() {
    date +%s
}

show_action_header() {
    local action="$1"
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${BOLD}$action${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

clear_database_task() {
    while true; do
        show_header
        show_action_header "Clear Database Tables"
        
        databases=()
        while IFS= read -r line; do
            databases+=("$line")
        done < <(list_databases)

        if [ ${#databases[@]} -eq 0 ]; then
            echo -e "${RED}No databases found.${NC}"
            echo -ne "\nPress Enter to return to main menu..."
            read
            return
        fi

        echo -e "${GREEN}Found ${#databases[@]} database(s)${NC}\n"
        
        if ! prompt_selection "Select database to clear:" "${databases[@]}"; then
            return
        fi
        db_name="${databases[$REPLY]}"
        
        echo -e "\n${DARK_YELLOW}⚠ Warning: This will delete all tables in ${BOLD}$db_name${NC}"
        echo -ne "${DARK_YELLOW}Type 'YES' to confirm (or press Enter to cancel): ${NC}"
        read confirmation
        
        if [[ "$confirmation" == "YES" ]]; then
            echo -e "\n${BLUE}▶ Processing database: ${BOLD}$db_name${NC}"
            local op_start=$(get_timestamp)
            drop_all_tables_forcefully "$db_name"
            local op_end=$(get_timestamp)
            local total_time=$((op_end - op_start))
            echo -e "\n${GREEN}✓ Total operation time: $(format_duration $total_time)${NC}"
            echo -ne "\nPress Enter to continue..."
            read
        else
            echo -e "\n${DARK_YELLOW}Operation cancelled${NC}"
            sleep 1
        fi
        
        echo -e "\n${BLUE}What would you like to do next?${NC}\n"
        echo -e "  ${GREEN}1${NC}. Clean another database"
        echo -e "  ${GREEN}2${NC}. Return to Main Menu"
        echo -e "  ${GREEN}3${NC}. Exit\n"
        
        while true; do
            echo -ne "${BOLD}Enter your choice [1-3]: ${NC}"
            read -r next_action
            case $next_action in
            1) break ;;
            2) return ;;
            3)
                echo -e "\n${GREEN}Thank you for using PostgreSQL Database Management System${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid selection. Please try again.${NC}"
                ;;
            esac
        done
    done
}

import_sql_file_task() {
    show_header
    show_action_header "Import SQL File"
    
    echo -e "${BLUE}▶ Scanning for SQL files in: ${NC}$DOWNLOADS_PATH\n"
    rename_sql_files "$DOWNLOADS_PATH"
    
    sql_files=()
    sql_files_display=()
    while IFS='|' read -r filename filesize; do
        sql_files+=("$filename")
        sql_files_display+=("$filename [${filesize}]")
    done < <(list_sql_files_with_sizes "$DOWNLOADS_PATH")
    
    if [ ${#sql_files[@]} -eq 0 ]; then
        echo -e "${RED}✗ No SQL files found in $DOWNLOADS_PATH${NC}"
        echo -ne "\nPress Enter to return to main menu..."
        read
        return
    fi

    echo -e "${GREEN}Found ${#sql_files[@]} SQL file(s)${NC}\n"
    
    while true; do
        if ! prompt_selection "Select SQL file to import:" "${sql_files_display[@]}"; then
            return
        fi
        sql_file="${sql_files[$REPLY]}"
        
        echo -e "\n${GREEN}▶ Selected file: ${BOLD}$sql_file${NC}\n"
        
        databases=()
        while IFS= read -r line; do
            databases+=("$line")
        done < <(list_databases)

        if [ ${#databases[@]} -eq 0 ]; then
            echo -e "${RED}✗ No databases found${NC}"
            echo -ne "\nPress Enter to return to main menu..."
            read
            return
        fi

        echo -e "${BLUE}Available target databases:${NC}\n"
        
        if ! prompt_selection "Select target database:" "${databases[@]}"; then
            return
        fi
        db_name="${databases[$REPLY]}"
        
        echo -e "\n${BLUE}▶ Target database: ${BOLD}$db_name${NC}"
        
        if check_if_database_contains_tables "$db_name"; then
            echo -e "${DARK_YELLOW}⚠ Warning: Database already contains tables${NC}"
            echo -ne "${DARK_YELLOW}Type 'OVERRIDE' to continue anyway (or press Enter to cancel): ${NC}"
            read confirmation
            if [[ "$confirmation" != "OVERRIDE" ]]; then
                echo -e "\n${DARK_YELLOW}Import cancelled${NC}"
                sleep 1
                continue
            fi
        fi
        
        echo -e "\n${BLUE}▶ Starting import operation...${NC}"
        local op_start=$(get_timestamp)
        import_sql_file "$db_name" "$sql_file"
        local op_end=$(get_timestamp)
        local total_time=$((op_end - op_start))
        echo -e "\n${GREEN}✓ Total operation time: $(format_duration $total_time)${NC}"
        echo -ne "\nPress Enter to return to main menu..."
        read
        break
    done
}

both_tasks() {
    show_header
    show_action_header "Clear Database and Import SQL"
    
    databases=()
    while IFS= read -r line; do
        databases+=("$line")
    done < <(list_databases)

    if [ ${#databases[@]} -eq 0 ]; then
        echo -e "${RED}✗ No databases found${NC}"
        echo -ne "\nPress Enter to return to main menu..."
        read
        return
    fi

    echo -e "${GREEN}Found ${#databases[@]} database(s)${NC}\n"
    
    while true; do
        if ! prompt_selection "Select database to reset:" "${databases[@]}"; then
            return
        fi
        db_name="${databases[$REPLY]}"
        
        echo -e "\n${BLUE}▶ Selected database: ${BOLD}$db_name${NC}\n"
        
        rename_sql_files "$DOWNLOADS_PATH"
        sql_files=()
        sql_files_display=()
        while IFS='|' read -r filename filesize; do
            sql_files+=("$filename")
            sql_files_display+=("$filename [${filesize}]")
        done < <(list_sql_files_with_sizes "$DOWNLOADS_PATH")
        
        if [ ${#sql_files[@]} -eq 0 ]; then
            echo -e "${RED}✗ No SQL files found in $DOWNLOADS_PATH${NC}"
            echo -ne "\nPress Enter to return to main menu..."
            read
            return
        fi

        echo -e "${GREEN}Found ${#sql_files[@]} SQL file(s)${NC}\n"
        
        if ! prompt_selection "Select SQL file to import after clearing:" "${sql_files_display[@]}"; then
            return
        fi
        sql_file="${sql_files[$REPLY]}"
        
        echo -e "\n${DARK_YELLOW}⚠ This operation will:${NC}"
        echo -e "  ${DARK_YELLOW}1. Delete all tables in ${BOLD}$db_name${NC}"
        echo -e "  ${DARK_YELLOW}2. Import ${BOLD}$sql_file${NC}\n"
        echo -ne "${DARK_YELLOW}Type 'PROCEED' to confirm (or press Enter to cancel): ${NC}"
        read confirmation
        
        if [[ "$confirmation" == "PROCEED" ]]; then
            local total_start=$(get_timestamp)
            echo -e "\n${BLUE}Starting combined operation at: $(date "+%I:%M:%S %p")${NC}"
            
            echo -e "\n${BLUE}Step 1/2: Clearing database...${NC}"
            drop_all_tables_forcefully "$db_name"
            
            echo -e "\n${BLUE}Step 2/2: Importing SQL file...${NC}"
            import_sql_file "$db_name" "$sql_file"
            
            local total_end=$(get_timestamp)
            local total_duration=$((total_end - total_start))
            
            echo -e "\n${GREEN}✓ All operations completed successfully${NC}"
            echo -e "${GREEN}✓ Total time: $(format_duration $total_duration)${NC}"
            echo -e "${GREEN}✓ Completed at: $(date "+%I:%M:%S %p")${NC}"
            echo -ne "\nPress Enter to return to main menu..."
            read
        else
            echo -e "\n${DARK_YELLOW}Operation cancelled${NC}"
            sleep 1
            continue
        fi
        break
    done
}

export_database_task() {
    while true; do
        show_header
        show_action_header "Export Database"
        
        databases=()
        while IFS= read -r line; do
            databases+=("$line")
        done < <(list_databases)

        if [ ${#databases[@]} -eq 0 ]; then
            echo -e "${RED}No databases found.${NC}"
            echo -ne "\nPress Enter to return to main menu..."
            read
            return
        fi

        echo -e "${GREEN}Found ${#databases[@]} database(s)${NC}\n"
        
        if ! prompt_selection "Select database to export:" "${databases[@]}"; then
            return
        fi
        db_name="${databases[$REPLY]}"
        
        echo -e "\n${BLUE}▶ Selected database: ${BOLD}$db_name${NC}\n"
        
        echo -e "${GREEN}Export Options:${NC}\n"
        echo -e "  ${GREEN}1${NC}. Export entire database (all tables, functions, triggers)"
        echo -e "  ${GREEN}2${NC}. Export specific table only"
        echo -e "  ${GREEN}3${NC}. Go Back\n"
        
        while true; do
            echo -ne "${BOLD}Select export type [1-3]: ${NC}"
            read -r export_choice
            
            case $export_choice in
            1)
                echo -e "\n${BLUE}▶ Export Type: Full Database Backup${NC}"
                local date_suffix=$(date "+%Y_%m_%d_%H%M%S")
                local export_filename="${db_name}_full_backup_${date_suffix}"
                export_filename=$(echo "$export_filename" | sed -e 's/[^A-Za-z0-9._-]/_/g' -e 's/__*/_/g')
                
                echo -e "${BLUE}▶ Export filename: ${BOLD}${export_filename}.sql${NC}"
                
                export_full_database "$db_name"
                echo -ne "\nPress Enter to continue..."
                read
                break
                ;;
            2)
                echo -e "\n${BLUE}▶ Export Type: Specific Table${NC}\n"
                
                tables=()
                while IFS= read -r line; do
                    tables+=("$line")
                done < <(list_tables "$db_name")
                
                if [ ${#tables[@]} -eq 0 ]; then
                    echo -e "${RED}No tables found in database $db_name${NC}"
                    echo -ne "\nPress Enter to continue..."
                    read
                    break
                fi
                
                echo -e "${GREEN}Found ${#tables[@]} table(s) in database${NC}\n"
                
                if ! prompt_selection "Select table to export:" "${tables[@]}"; then
                    break
                fi
                table_name="${tables[$REPLY]}"
                
                echo -e "\n${BLUE}▶ Selected table: ${BOLD}$table_name${NC}"
                
                local export_filename=$(format_export_filename "$db_name" "$table_name")
                local export_path="$DOWNLOADS_PATH/${export_filename}.sql"
                
                echo -e "${BLUE}▶ Export filename: ${BOLD}${export_filename}.sql${NC}"
                
                echo -e "\n${BLUE}▶ Starting export operation...${NC}"
                local start_time=$(get_timestamp)
                echo -e "${BLUE}Started at: $(date "+%I:%M:%S %p")${NC}"
                
                {
                    echo "-- PostgreSQL Database Export"
                    echo "-- Database: $db_name"
                    echo "-- Table: $table_name"
                    echo "-- Export Date: $(date '+%Y-%m-%d %H:%M:%S')"
                    echo "-- --------------------------------------------------------"
                    echo ""
                    echo "-- Table structure for table $table_name"
                    echo ""
                } > "$export_path"
                
                PGPASSWORD="$DB_PASS" "$PSQL_CMD" -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db_name" -c "\d $table_name" 2>/dev/null | sed 's/^/-- /' >> "$export_path"
                
                echo "" >> "$export_path"
                echo "-- Dumping data for table $table_name" >> "$export_path"
                echo "" >> "$export_path"
                
                PGPASSWORD="$DB_PASS" pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db_name" -t "$table_name" --data-only --column-inserts 2>/dev/null >> "$export_path"
                
                if [ $? -eq 0 ]; then
                    local end_time=$(get_timestamp)
                    local duration=$((end_time - start_time))
                    local file_size=$(ls -lh "$export_path" | awk '{print $5}')
                    
                    echo -e "\n${GREEN}✓ Export completed successfully${NC}"
                    echo -e "${GREEN}✓ File: ${export_filename}.sql (${file_size})${NC}"
                    echo -e "${GREEN}✓ Location: $DOWNLOADS_PATH${NC}"
                    echo -e "${GREEN}✓ Duration: $(format_duration $duration)${NC}"
                    echo -e "${GREEN}✓ Finished at: $(date "+%I:%M:%S %p")${NC}"
                else
                    echo -e "\n${RED}✗ Export failed${NC}"
                fi
                
                echo -ne "\nPress Enter to continue..."
                read
                break
                ;;
            3)
                break
                ;;
            *)
                echo -e "${RED}Invalid selection. Please enter 1, 2, or 3${NC}"
                ;;
            esac
        done
        
        echo -e "\n${BLUE}What would you like to do next?${NC}\n"
        echo -e "  ${GREEN}1${NC}. Export another database/table"
        echo -e "  ${GREEN}2${NC}. Return to Main Menu"
        echo -e "  ${GREEN}3${NC}. Exit\n"
        
        while true; do
            echo -ne "${BOLD}Enter your choice [1-3]: ${NC}"
            read -r next_action
            case $next_action in
            1) break ;;
            2) return ;;
            3)
                echo -e "\n${GREEN}Thank you for using PostgreSQL Database Management System${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid selection. Please try again.${NC}"
                ;;
            esac
        done
    done
}


main_menu() {
    show_header
    echo -e "${BOLD}Main Menu${NC}\n"
    echo -e "${GREEN}Available Operations:${NC}\n"
    echo -e "  ${GREEN}1${NC}. Clear Database       - Remove all tables from a database"
    echo -e "  ${GREEN}2${NC}. Import SQL File      - Import SQL file into a database"
    echo -e "  ${GREEN}3${NC}. Clear & Import       - Clear database then import SQL"
    echo -e "  ${GREEN}4${NC}. Export Database      - Export full database or specific table"
    echo -e "  ${GREEN}5${NC}. Exit\n"
    
    while true; do
        echo -ne "${BOLD}Select operation [1-5]: ${NC}"
        read -r choice
        
        case $choice in
        1)
            clear_database_task
            return
            ;;
        2)
            import_sql_file_task
            return
            ;;
        3)
            both_tasks
            return
            ;;
        4)
            export_database_task
            return
            ;;
        5)
            echo -e "\n${GREEN}Thank you for using PostgreSQL Database Management System${NC}\n"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid selection. Please enter a number between 1-5${NC}"
            ;;
        esac
    done
}

clear
echo -e "${GREEN}Initializing PostgreSQL Database Management System...${NC}"
echo -e "${BLUE}System Time: $(date "+%A, %B %d, %Y at %I:%M:%S %p")${NC}"
sleep 1

while true; do
    main_menu
done