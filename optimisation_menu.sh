#!/bin/bash
clear

while true; do
	echo "Optimisation Menu"
	echo "1. View User Resource Usage"
	echo "2. View Top 5 Intensive Programs"
	echo "3. Reduce CPU Usage"
	echo "4. View Consumption History" 
	echo "5. Exit"

	read -p "Enter your choice (1/2/3/4/5): " choice

	case "$choice" in
		1)
			#Option to view resource usage
			iostat
			;;
		2)
			#Option to view most intensive programs
			ps -eo %mem,%cpu,comm --sort=-%mem | head -n 6
			;;
		3)
			#Option to reduce CPU Usage
			./reduce_cpu.sh
			;;
		4)
			#Option to view history of resource consumption
			sar -ur
			;;
		5)
			echo "Exiting. Goodbye!"
			exit
			;;
		*)
			echo "Invalid choice. Please select one of the above." 
			;;
	esac

	#Pause and clear the screen
	read -p "Press Enter to continue..."
	clear
done
