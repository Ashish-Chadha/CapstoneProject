#!/bin/bash

# Color variables for user-friendly output
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No color

# Log file location
LOG_FILE="history_log.txt"

# Log function to record user actions
log_action() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to update the reduce_cpu script only
update_reduce_cpu() {
    echo -e "${CYAN}Updating reduce_cpu.sh from GitHub...${NC}"
    wget -O reduce_cpu.sh https://raw.githubusercontent.com/Ashish-Chadha/CapstoneProject/main/scripts/reduce_cpu.sh

    # Check if the download was successful
    if [[ $? -eq 0 ]]; then
        chmod +x reduce_cpu.sh # Make it executable
        echo -e "${GREEN}reduce_cpu.sh Updated Successfully!${NC}"
        log_action "reduce_cpu.sh updated from GitHub."
    else
        echo -e "${RED}Error: Failed to update reduce_cpu.sh.${NC}"
    fi
}

# Main menu
clear
trap "echo 'Exiting...'; exit" SIGINT

while true; do
    echo -e "${CYAN}==============================${NC}"
    echo -e "${CYAN}        Optimisation Menu      ${NC}"
    echo -e "${CYAN}==============================${NC}"
    echo -e "${GREEN}1. View User Resource Usage${NC}"
    echo -e "${GREEN}2. View Top 5 Intensive Programs${NC}"
    echo -e "${GREEN}3. Reduce CPU Usage${NC}"
    echo -e "${GREEN}4. View Consumption History${NC}"
    echo -e "${GREEN}5. Update reduce_cpu script${NC}"
    echo -e "${GREEN}6. Exit${NC}"
    echo -e "${CYAN}==============================${NC}"

    # Prompt user for input
    read -p "Enter your choice (1/2/3/4/5/6): " choice

    # Handle the user input with case
    case "$choice" in
        1)
            iostat
            ;;
        2)
            ps -eo %mem,%cpu,comm --sort=-%mem | head -n 6
            ;;
        3)
            ./reduce_cpu.sh
            ;;
        4)
            sar -ur
            ;;
        5)
            update_reduce_cpu
            ;;
        6)
            echo -e "${GREEN}Exiting. Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Please select a valid option (1-6).${NC}"
            ;;
    esac

    # Pause and clear the screen
    read -p "Press Enter to return to the menu..."
    clear
done
