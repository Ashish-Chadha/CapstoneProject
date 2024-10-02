#!/bin/bash

# Color variables for user-friendly output
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No color

# Log file location
LOG_FILE="history_log.txt"

# Log function to record user actions
log_action() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Dependency check function
check_dependency() {
    command -v "$1" &> /dev/null
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error: $1 is not installed. Please install it to use this feature.${NC}"
        log_action "$1 not found."
        return 1
    fi
    return 0
}

# Function to display the help menu
show_help() {
    echo -e "${CYAN}==============================${NC}"
    echo -e "${YELLOW}         Help Menu           ${NC}"
    echo -e "${CYAN}==============================${NC}"
    echo -e "${GREEN}1. View User Resource Usage${NC} - Displays detailed system resource usage via the iostat command."
    echo -e "${GREEN}2. View Top 5 Intensive Programs${NC} - Lists the top 5 memory-intensive programs running on the system."
    echo -e "${GREEN}3. Reduce CPU Usage${NC} - Runs a script to reduce CPU usage by terminating or lowering process priorities."
    echo -e "${GREEN}4. View Consumption History${NC} - Displays historical CPU and memory usage with sar."
    echo -e "${GREEN}5. Exit${NC} - Exits the script."
    echo -e "${GREEN}h. Help Menu${NC} - Displays this help menu."
    echo -e "${CYAN}==============================${NC}"
}

# Main menu
clear
trap "echo 'Exiting...'; exit" SIGINT

while true; do
    echo -e "${CYAN}==============================${NC}"
    echo -e "${YELLOW}        Optimisation Menu      ${NC}"
    echo -e "${CYAN}==============================${NC}"
    echo -e "${GREEN}1. View User Resource Usage${NC}"
    echo -e "${GREEN}2. View Top 5 Intensive Programs${NC}"
    echo -e "${GREEN}3. Reduce CPU Usage${NC}"
    echo -e "${GREEN}4. View Consumption History${NC}"
    echo -e "${GREEN}5. Exit${NC}"
    echo -e "${GREEN}h. Help Menu${NC}"
    echo -e "${CYAN}==============================${NC}"

    # Prompt user for input
    read -p "Enter your choice (1/2/3/4/5/h): " choice

    # Handle the user input with case
    case "$choice" in
        1)
            if check_dependency "iostat"; then
                echo -e "${CYAN}Displaying resource usage...${NC}"
                log_action "Selected: View User Resource Usage"
                iostat
            fi
            ;;
        2)
            echo -e "${CYAN}Displaying top 5 intensive programs...${NC}"
            log_action "Selected: View Top 5 Intensive Programs"
            ps -eo %mem,%cpu,comm --sort=-%mem | head -n 6
            ;;
        3)
            if [ -x ./reduce_cpu.sh ]; then
                echo -e "${CYAN}Reducing CPU usage...${NC}"
                log_action "Selected: Reduce CPU Usage"
                ./reduce_cpu.sh
            else
                echo -e "${RED}reduce_cpu.sh not found or not executable. Ensure the script exists and is executable.${NC}"
                log_action "reduce_cpu.sh not found or not executable"
            fi
            ;;
        4)
            if check_dependency "sar"; then
                echo -e "${CYAN}Displaying resource consumption history...${NC}"
                log_action "Selected: View Consumption History"
                sar -ur
            fi
            ;;
        5)
            echo -e "${GREEN}Exiting. Goodbye!${NC}"
            log_action "Exiting script"
            exit 0
            ;;
        h)
            log_action "Selected: Help Menu"
            show_help
            ;;
        *)
            echo -e "${RED}Invalid choice. Please select a valid option (1/2/3/4/5/h).${NC}"
            log_action "Invalid choice selected: $choice"
            ;;
    esac

    # Pause and clear the screen
    read -p "Press Enter to return to the menu..."
    clear
done
