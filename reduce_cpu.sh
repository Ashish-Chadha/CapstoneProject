#!/bin/bash

#==============================#
#         Color Codes          #
#==============================#
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
MAGENTA='\e[35m'
CYAN='\e[36m'
RESET='\e[0m'

#==============================#
#          Log File            #
#==============================#
LOG_FILE="optimisation_log.txt"

log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') : $1" >> $LOG_FILE
}

#==============================#
#       Notification Limits    #
#==============================#
DEFAULT_LIMIT=20
cpu_limit=$DEFAULT_LIMIT
mem_limit=$DEFAULT_LIMIT

notify_user() {
    local message=$1
    notify-send "Resource Alert" "$message"
    #echo -e "${RED}$message${RESET}"
    #log_action "Notification sent: $message"
}

check_resource_limits() {
    # Extract the top CPU process and usage, ensuring only numeric values are considered
    top_cpu_process=$(ps -eo pid,ppid,user,cmd,%cpu --sort=-%cpu | head -n 2 | tail -n 1)
    top_cpu_usage=$(echo $top_cpu_process | awk '{print int($5)}')
    
    #echo "Debug: Top CPU usage is $top_cpu_usage%"  # Debugging line

    # Check if the top CPU usage exceeds the limit
    if [ "$top_cpu_usage" -ge "$cpu_limit" ]; then
        notify_user "CPU usage by $(echo $top_cpu_process | awk '{print $4}') exceeded ${cpu_limit}% (currently ${top_cpu_usage}%)."
    fi
    
    # Extract the top memory process and usage, ensuring only numeric values are considered
    top_mem_process=$(ps -eo pid,ppid,user,cmd,%mem --sort=-%mem | head -n 2 | tail -n 1)
    top_mem_usage=$(echo $top_mem_process | awk '{print int($5)}')
    
    #echo "Debug: Top memory usage is $top_mem_usage%"  # Debugging line

    # Check if the top memory usage exceeds the limit
    if [ "$top_mem_usage" -ge "$mem_limit" ]; then
        notify_user "Memory usage by $(echo $top_mem_process | awk '{print $4}') exceeded ${mem_limit}% (currently ${top_mem_usage}%)."
    fi
}


#==============================#
#        Helper Functions      #
#==============================#

# Function to display the top CPU-consuming processes
show_top_processes() {
    echo -e "${CYAN}Top CPU-consuming processes:${RESET}"
    ps -eo pid,ppid,user,cmd,%mem,%cpu --sort=-%cpu | head -n 11
}

# Function to display the main menu
show_menu() {
    echo -e "${GREEN}====================================================="
    echo "    CPU & Memory Optimisation Menu      "
    echo "=====================================================${RESET}"
    echo -e "${YELLOW}1. Quick Optimization${RESET}"
    echo "   Perform recommended optimizations automatically."
    echo -e "${YELLOW}2. Show top CPU-consuming processes${RESET}"
    echo "   Displays a list of processes using the most CPU."
    echo -e "${YELLOW}3. Terminate a process${RESET}"
    echo "   Stop a process that is consuming excessive CPU."
    echo -e "${YELLOW}4. Lower process priority (Nice Value)${RESET}"
    echo "   Reduce the priority of a process to lower its CPU usage."
    echo -e "${YELLOW}5. Limit CPU usage of a process${RESET}"
    echo "   Set a maximum CPU usage limit for a specific process."
    echo -e "${YELLOW}6. Stop unnecessary services${RESET}"
    echo "   Disable background services that are not needed."
    echo -e "${YELLOW}7. Kill zombie processes${RESET}"
    echo "   Terminate processes that are no longer active."
    echo -e "${YELLOW}8. Clear cached memory${RESET}"
    echo "   Free up system memory by clearing cache."
    echo -e "${YELLOW}9. Monitor High Latency${RESET}"
    echo "   Check and Monitor Netowrk Latency."
    echo -e "${YELLOW}10. View optimization log${RESET}"
    echo "   Display a log of all actions performed."
    echo -e "${YELLOW}11. Undo last action${RESET}"
    echo "   Revert the most recent optimization action."
    echo -e "${YELLOW}12. Set Resource Limits${RESET}"
    echo "   Set CPU and Memory usage limits for notifications."
    echo -e "${YELLOW}13. Recommend Actions${RESET}"
    echo "   Gives you recommendations based off current resource status."
    echo -e "${YELLOW}14. Help${RESET}"
    echo "   Get detailed information about each option."
    echo -e "${YELLOW}15. Exit${RESET}"
    echo ""
    echo -e "${MAGENTA}Enter your choice (1-15):${RESET}"
}

# Function for Quick Optimization
quick_optimization() {
    echo -e "${BLUE}Performing Quick Optimization...${RESET}"
    stop_unnecessary_services "silent"
    clear_cached_memory "silent"
    kill_zombie_processes "silent"
    monitor_high_latency "silent"
    echo -e "${GREEN}Quick Optimization completed successfully.${RESET}"
    log_action "Performed Quick Optimization."
    pause_and_clear
}

# Function to pause and clear screen
pause_and_clear() {
    read -n 1 -s -r -p "$(echo -e ${MAGENTA}'Press any key to continue...')"
    clear
}

#==============================#
#      Individual Functions    #
#==============================#

# Function to terminate a process
terminate_process() {
    show_top_processes
    echo ""
    while true; do
        echo -e "${MAGENTA}Enter the PID of the process you want to terminate (or type 'exit' to return to the menu, 'help' for assistance):${RESET}"
        read pid
        if [ "$pid" == "exit" ]; then
            return
        elif [ "$pid" == "help" ]; then
            echo -e "${YELLOW}Enter the Process ID (PID) from the list above. Terminating a process will stop it from running.${RESET}"
            continue
        elif ! [[ "$pid" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}Invalid input. Please enter a numeric PID.${RESET}"
            continue
        fi

        if ps -p $pid > /dev/null; then
            process_name=$(ps -p $pid -o comm=)
            echo -e "${YELLOW}You are about to terminate process '${process_name}' with PID $pid.${RESET}"
            
            # Check for critical processes
            critical_processes=("systemd" "init" "kthreadd" "bash")
            if [[ " ${critical_processes[@]} " =~ " ${process_name} " ]]; then
                echo -e "${RED}Warning: Terminating this critical system process could destabilize your system.${RESET}"
                echo -e "${MAGENTA}Are you sure you want to continue? (y/n):${RESET}"
                read confirm
                if [ "$confirm" != "y" ]; then
                    echo -e "${GREEN}Action cancelled. Returning to menu.${RESET}"
                    pause_and_clear
                    return
                fi
            else
                echo -e "${MAGENTA}Are you sure you want to terminate this process? (y/n):${RESET}"
                read confirm
                if [ "$confirm" == "y" ]; then
                    kill -9 $pid && echo -e "${GREEN}Process $pid terminated successfully.${RESET}" || echo -e "${RED}Failed to terminate process $pid.${RESET}"
                    log_action "Terminated process $pid ($process_name)."
                else
                    echo -e "${GREEN}Action cancelled.${RESET}"
                fi
            fi
            break
        else
            echo -e "${RED}Process with PID $pid does not exist.${RESET}"
        fi
    done
    pause_and_clear
}

# Function to lower the priority of a process (Nice Value)
lower_process_priority() {
    show_top_processes
    echo ""
    while true; do
        echo -e "${MAGENTA}Enter the PID of the process you want to renice (or type 'exit' to return to the menu, 'help' for assistance):${RESET}"
        read pid
        if [ "$pid" == "exit" ]; then
            return
        elif [ "$pid" == "help" ]; then
            echo -e "${YELLOW}Enter the Process ID (PID) from the list above. Lowering priority makes the process use less CPU.${RESET}"
            continue
        elif ! [[ "$pid" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}Invalid input. Please enter a numeric PID.${RESET}"
            continue
        fi

        echo -e "${MAGENTA}Enter the nice value (-20 to 19, default is 0). Higher value means lower priority:${RESET}"
        read nice_value
        if ! [[ "$nice_value" =~ ^-?[0-9]+$ ]] || [ "$nice_value" -lt -20 ] || [ "$nice_value" -gt 19 ]; then
            echo -e "${RED}Invalid nice value. Please enter a number between -20 and 19.${RESET}"
            continue
        fi

        sudo renice $nice_value -p $pid && echo -e "${GREEN}Process $pid priority changed to $nice_value successfully.${RESET}" || echo -e "${RED}Failed to change priority for process $pid.${RESET}"
        log_action "Changed priority of process $pid to $nice_value."
        break
    done
    pause_and_clear
}

# Function to limit CPU usage of a specific process
limit_cpu_usage() {
    if ! command -v cpulimit &> /dev/null; then
        echo -e "${YELLOW}cpulimit is not installed. Installing cpulimit...${RESET}"
        sudo yum install cpulimit -y || { echo -e "${RED}Failed to install cpulimit. Please install it manually.${RESET}"; pause_and_clear; return; }
    fi

    show_top_processes
    echo ""
    while true; do
        echo -e "${MAGENTA}Enter the PID of the process you want to limit (or type 'exit' to return to the menu, 'help' for assistance):${RESET}"
        read pid
        if [ "$pid" == "exit" ]; then
            return
        elif [ "$pid" == "help" ]; then
            echo -e "${YELLOW}Enter the Process ID (PID) from the list above. Limiting CPU usage restricts the process to a set CPU percentage.${RESET}"
            continue
        elif ! [[ "$pid" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}Invalid input. Please enter a numeric PID.${RESET}"
            continue
        fi

        echo -e "${MAGENTA}Enter the maximum CPU percentage you want to allow (e.g., 20 for 20%):${RESET}"
        read cpu_limit
        if ! [[ "$cpu_limit" =~ ^[0-9]+$ ]] || [ "$cpu_limit" -le 0 ] || [ "$cpu_limit" -gt 100 ]; then
            echo -e "${RED}Invalid CPU limit. Please enter a number between 1 and 100.${RESET}"
            continue
        fi

        sudo cpulimit -p $pid -l $cpu_limit && echo -e "${GREEN}Process $pid is now limited to $cpu_limit% CPU usage.${RESET}" || echo -e "${RED}Failed to limit CPU usage for process $pid.${RESET}"
        log_action "Limited CPU usage of process $pid to $cpu_limit%."
        break
    done
    pause_and_clear
}

# Function to stop unnecessary services
stop_unnecessary_services() {
    echo -e "${BLUE}Identifying unnecessary services...${RESET}"
    services=("bluetooth" "cups" "apache2" "mysql" "avahi-daemon")
    stopped_services=()
    for service in "${services[@]}"; do
        if systemctl is-active --quiet $service; then
            sudo systemctl stop $service && echo -e "${GREEN}Stopped service: $service.${RESET}" || echo -e "${RED}Failed to stop service: $service.${RESET}"
            stopped_services+=($service)
        else
            echo -e "${YELLOW}Service $service is not running.${RESET}"
        fi
    done
    if [ "$1" != "silent" ]; then
        log_action "Stopped services: ${stopped_services[*]}."
        pause_and_clear
    fi
}

# Function to kill zombie processes
kill_zombie_processes() {
    echo -e "${BLUE}Checking for zombie processes...${RESET}"
    zombies=$(ps aux | awk '{ if ($8 == "Z") print $2 }')
    if [ -z "$zombies" ]; then
        echo -e "${GREEN}No zombie processes found.${RESET}"
    else
        for zpid in $zombies; do
            sudo kill -9 $zpid && echo -e "${GREEN}Killed zombie process $zpid.${RESET}" || echo -e "${RED}Failed to kill zombie process $zpid.${RESET}"
            log_action "Killed zombie process $zpid."
        done
    fi
    if [ "$1" != "silent" ]; then
        pause_and_clear
    fi
}

# Function to clear cached memory
clear_cached_memory() {
    echo -e "${BLUE}Clearing cached memory...${RESET}"
    sudo sync && sudo sysctl -w vm.drop_caches=3 && echo -e "${GREEN}Cached memory cleared successfully.${RESET}" || echo -e "${RED}Failed to clear cached memory.${RESET}"
    if [ "$1" != "silent" ]; then
        log_action "Cleared cached memory."
        pause_and_clear
    fi
}

# Function to monitor network latency
monitor_high_latency() {
    echo -e "${BLUE}Checking network latency...${RESET}"
    default_threshold=100 # ms, default latency threshold

    # Ask user for latency threshold
    echo -e "${MAGENTA}Enter a network latency threshold in ms (current: $default_threshold):${RESET}"
    read latency_threshold
    if ! [[ "$latency_threshold" =~ ^[0-9]+$ ]]; then
        latency_threshold=$default_threshold
    fi

    echo -e "${YELLOW}Pinging google.com to check for latency...${RESET}"
    latency=$(ping -c 4 google.com | tail -1 | awk -F '/' '{print $5}') # Get average latency in ms

    if [[ -z "$latency" ]]; then
        echo -e "${RED}Unable to retrieve network latency.${RESET}"
    else
        echo -e "${GREEN}Average latency: ${latency}ms.${RESET}"
        
        if (( $(echo "$latency > $latency_threshold" | bc -l) )); then
            echo -e "${RED}Warning: High network latency detected (${latency}ms > ${latency_threshold}ms).${RESET}"

            echo -e "${MAGENTA}Would you like to run network diagnostics and get a simplified report? (y/n):${RESET}"
            read confirm
            if [ "$confirm" == "y" ]; then
                echo -e "${BLUE}Running network diagnostics...${RESET}"
                
                # Display a simplified version of network diagnostics using netstat and explain key points
                echo -e "${YELLOW}Checking network interface statistics...${RESET}"
                netstat_output=$(netstat -i)

                # Parse netstat output for user-friendly information
                echo -e "${GREEN}Network Diagnostics Report:${RESET}"
                echo "$netstat_output" | awk '
                    BEGIN { print "\nNetwork Interface Summary:\n" }
                    NR==1 { print $0; next }  # Print header
                    {
                        iface=$1; rx_errs=$4; tx_errs=$8; dropped=$11;
                        printf("Interface: %s\n", iface);
                        printf("  RX Errors: %s\n", rx_errs);
                        printf("  TX Errors: %s\n", tx_errs);
                        printf("  Dropped Packets: %s\n", dropped);
                        print "-------------------------";
                    }'

                echo -e "${YELLOW}\nWhat this means:${RESET}"
                echo -e "${BLUE}RX Errors${RESET}: Number of errors in receiving data packets."
                echo -e "${BLUE}TX Errors${RESET}: Number of errors in sending data packets."
                echo -e "${BLUE}Dropped Packets${RESET}: Number of packets lost due to congestion or other network issues."
                echo -e "${GREEN}If these numbers are high, it could indicate network issues causing latency.${RESET}"
            fi
        else
            echo -e "${GREEN}Network latency is within acceptable limits.${RESET}"
        fi
    fi

    log_action "Checked network latency: ${latency}ms."
    pause_and_clear
}

# Function to view optimization log
view_optimization_log() {
    if [ -f "$LOG_FILE" ]; then
        echo -e "${CYAN}Optimization Log:${RESET}"
        cat $LOG_FILE
    else
        echo -e "${YELLOW}No log file found.${RESET}"
    fi
    pause_and_clear
}

# Function to undo last action
undo_last_action() {
    if [ -f "$LOG_FILE" ]; then
        last_action=$(tail -n 1 $LOG_FILE)
        echo -e "${CYAN}Undoing last action: $last_action${RESET}"

        # Handle different types of actions by checking their logs
        if [[ "$last_action" == *"Terminated process"* ]]; then
            # Undo process termination is not possible
            echo -e "${YELLOW}Cannot undo process termination.${RESET}"

        elif [[ "$last_action" == *"Changed priority of process"* ]]; then
            pid=$(echo "$last_action" | grep -oP '(?<=process )\d+')
            original_priority=0  # Assumes the original priority was 0 (default)
            echo -e "${CYAN}Restoring priority of process $pid to $original_priority.${RESET}"
            sudo renice $original_priority -p $pid
            log_action "Restored priority of process $pid to $original_priority."

        elif [[ "$last_action" == *"Limited CPU usage of process"* ]]; then
            pid=$(echo "$last_action" | grep -oP '(?<=process )\d+')
            echo -e "${CYAN}Removing CPU usage limit on process $pid.${RESET}"
            sudo killall -SIGCONT $pid
            log_action "Removed CPU usage limit from process $pid."

        elif [[ "$last_action" == *"Stopped services:"* ]]; then
            services_to_start=$(echo "$last_action" | cut -d':' -f2)
            for service in $services_to_start; do
                sudo systemctl start $service && echo -e "${GREEN}Restarted service: $service.${RESET}" || echo -e "${RED}Failed to restart service: $service.${RESET}"
            done
            log_action "Undid stopping services: $services_to_start."

	elif [[ "$last_action" == *"Killed zombie process"* ]]; then
            echo -e "${YELLOW}Cannot undo killing zombie processes.${RESET}"
            echo -e "${MAGENTA}Once a zombie process is killed, it cannot be restored.${RESET}"
            log_action "Attempted to undo killing zombie processes but could not."

        elif [[ "$last_action" == *"Cleared cached memory."* ]]; then
            echo -e "${YELLOW}Cannot undo clearing cached memory.${RESET}"

        else
            echo -e "${YELLOW}No reversible action found.${RESET}"
        fi
    else
        echo -e "${YELLOW}No log file found to undo actions.${RESET}"
    fi
    pause_and_clear
}

# Function to set resource limits for notifications
set_resource_limits() {
    echo -e "${MAGENTA}Enter the CPU usage limit for notifications (1-100, current is ${cpu_limit}%):${RESET}"
    read new_cpu_limit
    if ! [[ "$new_cpu_limit" =~ ^[0-9]+$ ]] || [ "$new_cpu_limit" -lt 1 ] || [ "$new_cpu_limit" -gt 100 ]; then
        echo -e "${RED}Invalid CPU limit. Please enter a number between 1 and 100.${RESET}"
    else
        cpu_limit=$new_cpu_limit
        echo -e "${GREEN}CPU limit set to ${cpu_limit}%.${RESET}"
    fi

    echo -e "${MAGENTA}Enter the memory usage limit for notifications (1-100, current is ${mem_limit}%):${RESET}"
    read new_mem_limit
    if ! [[ "$new_mem_limit" =~ ^[0-9]+$ ]] || [ "$new_mem_limit" -lt 1 ] || [ "$new_mem_limit" -gt 100 ]; then
        echo -e "${RED}Invalid memory limit. Please enter a number between 1 and 100.${RESET}"
    else
        mem_limit=$new_mem_limit
        echo -e "${GREEN}Memory limit set to ${mem_limit}%.${RESET}"
    fi
    pause_and_clear
}

# Function to recommend actions based on CPU usage
recommend_actions() {
    echo -e "${BLUE}Analyzing CPU usage...${RESET}"
    top_process=$(ps -eo pid,ppid,cmd,%cpu --sort=-%cpu | head -2 | tail -1)
    cpu_usage=$(echo $top_process | awk '{print $4}')
    pid=$(echo $top_process | awk '{print $1}')
    cmd=$(echo $top_process | awk '{print $3}')
    
    if (( $(echo "$cpu_usage > 80.0" | bc -l) )); then
        echo -e "${RED}High CPU usage detected: Process ${cmd} with PID $pid is using ${cpu_usage}% CPU.${RESET}"
        echo -e "${YELLOW}Recommended Actions:${RESET}"
        echo "1. Terminate the process (Use Option 3: Terminate a Process and enter $pid or use 'kill $pid')."
        echo "2. Lower its priority (Use Option 4: Lower Process Priority and enter $pid or use 'renice 19 $pid')."
        echo "3. Limit the CPU usage (Use Option 5: Limit CPU usage and enter $pid or use 'cpulimit -p $pid -l 50')."
    elif (( $(echo "$cpu_usage > 50.0" | bc -l) )); then
        echo -e "${YELLOW}Moderate CPU usage detected: Process ${cmd} is using ${cpu_usage}% CPU.${RESET}"
        echo -e "Recommended Actions:"
        echo "1. Monitor the process or reduce its priority."
        echo "2. Clear system cache to free up resources."
    else
        echo -e "${GREEN}CPU usage is normal. No immediate actions required.${RESET}"
    fi
    pause_and_clear
}


# Function for interactive help
interactive_help() {
    clear
    echo -e "${GREEN}========== Help Menu ==========${RESET}"
    echo -e "${YELLOW}Select an option to learn more:${RESET}"
    echo "1. Quick Optimization"
    echo "2. Show top CPU-consuming processes"
    echo "3. Terminate a process"
    echo "4. Lower process priority (Nice Value)"
    echo "5. Limit CPU usage of a process"
    echo "6. Stop unnecessary services"
    echo "7. Kill zombie processes"
    echo "8. Clear cached memory"
    echo "9. Check Netork Latency"
    echo "10. Set Resource Limits"
    echo "11. Recommend Actions"
    echo "12. Back to Main Menu"
    echo ""
    echo -e "${MAGENTA}Enter your choice (1-12):${RESET}"
    read help_choice
    clear
    case $help_choice in
        1)
            echo -e "${CYAN}Quick Optimization:${RESET}"
            echo "This option performs several recommended optimizations automatically, including:"
            echo "- Stopping unnecessary services"
            echo "- Killing zombie processes"
            echo "- Clearing cached memory"
            ;;
        2)
            echo -e "${CYAN}Show top CPU-consuming processes:${RESET}"
            echo "Displays the top 10 processes currently consuming the most CPU resources."
            ;;
        3)
            echo -e "${CYAN}Terminate a process:${RESET}"
            echo "Allows you to stop a process that is consuming too much CPU by entering its PID."
            ;;
        4)
            echo -e "${CYAN}Lower process priority (Nice Value):${RESET}"
            echo "Reduces the priority of a process so that it uses less CPU compared to other processes."
            ;;
        5)
            echo -e "${CYAN}Limit CPU usage of a process:${RESET}"
            echo "Sets a maximum CPU usage percentage for a specific process to prevent it from overusing CPU resources."
            ;;
        6)
            echo -e "${CYAN}Stop unnecessary services:${RESET}"
            echo "Stops background services that are not essential, freeing up CPU and memory resources."
            ;;
        7)
            echo -e "${CYAN}Kill zombie processes:${RESET}"
            echo "Terminates processes that have completed execution but still occupy system resources."
            ;;
        8)
            echo -e "${CYAN}Clear cached memory:${RESET}"
            echo "Frees up system memory by clearing cached data that is no longer needed."
            ;;
	9)
            echo -e "${CYAN}Monitors and Check Network Latency:${RESET}"
            echo "Pings a reliable server (e.g., google.com) to check for network latency and then runs network diagnostics if latency exceeds the user-defined threshold."
	    ;;
	10)
            echo -e "${CYAN}Sets Resource Limits for Notifications:${RESET}"
            echo "Allows you to set limits for your system, which will later provide you with notifications when they are breached."
	    ;;
     	11)
      	    echo -e "${CYAN}Gives Recommendtions on Actions to take for Optimisation:${RESET}"
            echo "Gives you a recommendation of what potential actions can be taken depending on the current state of the recources being consumed."
	    ;;
        12)
            return
            ;;
        *)
            echo -e "${RED}Invalid choice. Returning to main menu.${RESET}"
            ;;
    esac
    pause_and_clear
}

#==============================#
#       Main Execution Loop    #
#==============================#

while true; do
    clear
    show_menu
    read choice

    case $choice in
        1)
            check_resource_limits
            quick_optimization
            ;;
        2)
            check_resource_limits
            show_top_processes
            pause_and_clear
            ;;
        3)
            check_resource_limits
            terminate_process
            ;;
        4)
            check_resource_limits
            lower_process_priority
            ;;
        5)
            check_resource_limits
            limit_cpu_usage
            ;;
        6)
            check_resource_limits
            stop_unnecessary_services
            ;;
        7)
            check_resource_limits
            kill_zombie_processes
            ;;
        8)
            check_resource_limits
            clear_cached_memory
            ;;
        9)
            check_resource_limits
            monitor_high_latency
            ;;
        10)
            check_resource_limits
            view_optimization_log
            ;;
        11)
            check_resource_limits
            undo_last_action
            ;;
        12)
            check_resource_limits
            set_resource_limits
            ;;
	13)
 	    check_resource_limits
      	    recommend_actions
	    ;;
        14)
            check_resource_limits
            interactive_help
            ;;
        15)
            check_resource_limits
            echo -e "${BLUE}Exiting the program. Goodbye!${RESET}"
            break
            ;;
        *)
            check_resource_limits
            echo -e "${RED}Invalid option. Please select a valid option (1-15).${RESET}"
            pause_and_clear
            ;;
    esac
done
