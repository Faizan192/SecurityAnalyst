#!/bin/bash

# Security Monitoring Script for Linux

LOG_FILE="/var/log/security_monitor.log"

# Function to check if the system is up-to-date
check_updates() {
    echo "Checking for system updates..."
    sudo apt update -q && sudo apt upgrade -y > /dev/null
    if [[ $? -eq 0 ]]; then
        echo "$(date) - System updated successfully" >> $LOG_FILE
    else
        echo "$(date) - Failed to update system" >> $LOG_FILE
    fi
}

# Function to monitor unauthorized login attempts
check_unauthorized_logins() {
    echo "Checking for unauthorized login attempts..."
    lastb | head -n 10 > /tmp/lastb_output.txt
    if [[ -s /tmp/lastb_output.txt ]]; then
        echo "$(date) - Unauthorized login attempts detected:" >> $LOG_FILE
        cat /tmp/lastb_output.txt >> $LOG_FILE
    else
        echo "$(date) - No unauthorized login attempts detected" >> $LOG_FILE
    fi
}

# Function to monitor suspicious entries in authentication logs
check_auth_log() {
    echo "Checking authentication logs for suspicious activity..."
    grep -i 'failed' /var/log/auth.log | tail -n 20 > /tmp/auth_failures.txt
    if [[ -s /tmp/auth_failures.txt ]]; then
        echo "$(date) - Failed login attempts found:" >> $LOG_FILE
        cat /tmp/auth_failures.txt >> $LOG_FILE
    else
        echo "$(date) - No failed login attempts found" >> $LOG_FILE
    fi
}

# Function to check for root login attempts
check_root_logins() {
    echo "Checking for root login attempts..."
    grep -i 'root' /var/log/auth.log | grep -i 'session opened' | tail -n 10 > /tmp/root_logins.txt
    if [[ -s /tmp/root_logins.txt ]]; then
        echo "$(date) - Root login attempts found:" >> $LOG_FILE
        cat /tmp/root_logins.txt >> $LOG_FILE
    else
        echo "$(date) - No root login attempts found" >> $LOG_FILE
    fi
}

# Function to check for failed sudo attempts
check_sudo_failures() {
    echo "Checking for failed sudo attempts..."
    grep -i 'sudo' /var/log/auth.log | grep -i 'failure' | tail -n 20 > /tmp/sudo_failures.txt
    if [[ -s /tmp/sudo_failures.txt ]]; then
        echo "$(date) - Failed sudo attempts detected:" >> $LOG_FILE
        cat /tmp/sudo_failures.txt >> $LOG_FILE
    else
        echo "$(date) - No failed sudo attempts detected" >> $LOG_FILE
    fi
}

# Function to monitor disk usage (alert on high disk usage)
check_disk_usage() {
    echo "Checking disk usage..."
    DISK_USAGE=$(df -h / | grep / | awk '{ print $5 }' | sed 's/%//g')
    if [[ $DISK_USAGE -ge 80 ]]; then
        echo "$(date) - Warning: Disk usage is above 80%: $DISK_USAGE%" >> $LOG_FILE
    else
        echo "$(date) - Disk usage is normal: $DISK_USAGE%" >> $LOG_FILE
    fi
}

# Function to check for open ports
check_open_ports() {
    echo "Checking open ports..."
    OPEN_PORTS=$(netstat -tuln | grep -E 'tcp|udp' | awk '{print $4}' | cut -d ':' -f2)
    if [[ -n $OPEN_PORTS ]]; then
        echo "$(date) - Open ports detected:" >> $LOG_FILE
        echo "$OPEN_PORTS" >> $LOG_FILE
    else
        echo "$(date) - No open ports found" >> $LOG_FILE
    fi
}

# Main monitoring script execution
echo "$(date) - Starting security monitoring..." > $LOG_FILE
check_updates
check_unauthorized_logins
check_auth_log
check_root_logins
check_sudo_failures
check_disk_usage
check_open_ports
echo "$(date) - Security monitoring completed." >> $LOG_FILE

# Send an email or alert if needed
# Uncomment below if you have mail configured
# mail -s "Security Monitoring Report" youremail@example.com < $LOG_FILE
