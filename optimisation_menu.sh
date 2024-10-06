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

# Function to update the reduce_cpu.sh script
update_reduce_cpu_script() {
    echo -e "${CYAN}Updating reduce_cpu.sh from GitHub...${NC}"

    # Remove the existing reduce_cpu.sh file
    if [[ -f ./reduce_cpu.sh ]]; then
        rm ./reduce_cpu.sh
        echo -e "${GREEN}Old reduce_cpu.sh has been deleted.${NC}"
    fi

    # Download the new reduce_cpu.sh from the GitHub repository
    curl -O https://raw.githubusercontent.com/Ashish-Chadha/CapstoneProject/main/reduce_cpu.sh

    # Check if the download was successful
    if [[ -f ./reduce_cpu.sh ]]; then
        chmod +x ./reduce_cpu.sh
        echo -e "${GREEN}reduce_cpu.sh has been downloaded successfully.${NC}"
        log_action "reduce_cpu.sh downloaded from GitHub."
    else
        echo -e "${RED}Error: Failed to download reduce_cpu.sh.${NC}"
    fi
}

# Function to update drivers
update_drivers() {
    echo "Checking for available driver updates..."
    
    # Check for available updates related to drivers
    if dnf check-update | grep -i driver; then
        echo "Drivers available for update. Proceeding with update..."
        
        # Update all available drivers
        sudo dnf update -y $(dnf check-update | grep -i driver | awk '{print $1}')
        
        echo "Driver updates completed."
    else
        echo "No driver updates available."
    fi
    
    # Provide feedback to the user
    echo "Update driver process complete."
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
    echo -e "${GREEN}5. Update CPU and Memory Reduction Program${NC} - Updates the Option 3 from menu from the GitHub repository."
    echo -e "${GREEN}6. Exit${NC} - Exits the script."
    echo -e "${GREEN}h. Help Menu${NC} - Displays this help menu."
    echo -e "${CYAN}==============================${NC}"
}

# Function to display the Admin Guide
show_admin_guide() {
    echo -e "${CYAN}==============================${NC}"
    echo -e "${YELLOW}       Admin's Guide           ${NC}"
    echo -e "${CYAN}==============================${NC}"
    echo -e "${GREEN}This guide covers how to manage and optimize the VM, including:${NC}"
    echo -e "${GREEN}1. System monitoring and performance tracking${NC}"
    echo -e "${GREEN}2. Updating and maintaining drivers${NC}"
    echo -e "${GREEN}3. Running the reduce_cpu script for optimization${NC}"
    echo -e "${GREEN}4. Keeping the system secure and updated${NC}"
    echo -e "${GREEN}5. Viewing user consumption history - make sure to view the logs within the files or through the system${NC}"
    echo -e "${CYAN}==============================${NC}"
}

# Function to handle admin guide access
admin_guide_access() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}This operation requires root access. Please enter your password to proceed.${NC}"
        sudo -k # Force asking for password
        if sudo true; then
            echo -e "${GREEN}Access granted! Displaying Admin's Guide...${NC}"
            log_action "Admin Guide accessed by a user with root privilege"
            show_admin_guide
        else
            echo -e "${RED}Access denied! Incorrect password.${NC}"
            log_action "Failed attempt to access Admin Guide"
        fi
    else
        echo -e "${GREEN}You are logged in as root. Displaying Admin's Guide...${NC}"
        log_action "Admin Guide accessed by root user"
        show_admin_guide
    fi
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
    echo -e "${GREEN}5. Update CPU and Memory Reduction Program${NC}"
    echo -e "${GREEN}6. Update VM Drivers${NC}"
    echo -e "${GREEN}7. Admin Guide (Restricted Access)${NC}"
    echo -e "${GREEN}8. Exit${NC}"
    echo -e "${GREEN}h. Help Menu${NC}"
    echo -e "${CYAN}==============================${NC}"

    # Prompt user for input
    read -p "Enter your choice (1/2/3/4/5/6//7/8/h): " choice

    # Handle the user input with case
    case "$choice" in
        1)
            echo -e "${CYAN}Displaying resource usage...${NC}"
            log_action "Selected: View User Resource Usage"
            iostat
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
            echo -e "${CYAN}Displaying resource consumption history...${NC}"
            log_action "Selected: View Consumption History"
            sar -ur
            ;;
        5)
            update_reduce_cpu_script
            ;;
        6)
            update_drivers
            ;;
        7)
            admin_guide_access
            ;;
        8)
            echo -e "${GREEN}Exiting. Goodbye!${NC}"
            log_action "Exiting script"
            exit 0
            ;;
        h)
            log_action "Selected: Help Menu"
            show_help
            ;;
        *)
            echo -e "${RED}Invalid choice. Please select a valid option (1/2/3/4/5/6/h).${NC}"
            log_action "Invalid choice selected: $choice"
            ;;
    esac

    # Pause and clear the screen
    read -p "Press Enter to return to the menu..."
    clear
done
