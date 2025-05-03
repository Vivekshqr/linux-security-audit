#!/bin/bash

# Security Audit Script for Linux Servers
# Usage: sudo ./security_audit.sh

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

# Define report file
REPORT_FILE="../reports/audit_report.txt"
CONFIG_FILE="../config/custom_checks.conf"
> "$REPORT_FILE"

# Function to log messages to report
log_to_report() {
    echo -e "$1" | tee -a "$REPORT_FILE"
}

# 1. User and Group Audits
audit_users_groups() {
    log_to_report "\n=== User and Group Audit ==="
    log_to_report "Listing all users:"
    cut -d: -f1 /etc/passwd | tee -a "$REPORT_FILE"
    
    log_to_report "\nUsers with UID 0 (root privileges):"
    awk -F: '$3 == 0 {print $1}' /etc/passwd | tee -a "$REPORT_FILE"
    
    log_to_report "\nChecking for users without passwords:"
    awk -F: '($2 == "") {print $1}' /etc/shadow | tee -a "$REPORT_FILE"
}

# 2. File and Directory Permissions
audit_file_permissions() {
    log_to_report "\n=== File and Directory Permissions ==="
    log_to_report "World-writable files and directories:"
    find / -perm -o+w -type f -o -perm -o+w -type d 2>/dev/null | tee -a "$REPORT_FILE"
    
    log_to_report "\nChecking .ssh directory permissions:"
    find /home -name ".ssh" -exec ls -ld {} \; 2>/dev/null | tee -a "$REPORT_FILE"
    
    log_to_report "\nFiles with SUID/SGID bits:"
    find / -perm /u=s -o -perm /g=s 2>/dev/null | tee -a "$REPORT_FILE"
}

# 3. Service Audits
audit_services() {
    log_to_report "\n=== Service Audit ==="
    log_to_report "Running services:"
    systemctl list-units --type=service --state=running | tee -a "$REPORT_FILE"
    
    log_to_report "\nChecking for sshd service:"
    systemctl is-active sshd && log_to_report "sshd is running" || log_to_report "sshd is not running"
    
    log_to_report "\nOpen ports and services:"
    netstat -tuln 2>/dev/null | tee -a "$REPORT_FILE"
}

# 4. Firewall and Network Security
audit_firewall_network() {
    log_to_report "\n=== Firewall and Network Security ==="
    if command -v ufw >/dev/null; then
        log_to_report "UFW status:"
        ufw status | tee -a "$REPORT_FILE"
    elif command -v iptables >/dev/null; then
        log_to_report "iptables rules:"
        iptables -L -n -v | tee -a "$REPORT_FILE"
    else
        log_to_report "No firewall (ufw or iptables) found"
    fi
    
    log_to_report "\nIP forwarding status:"
    sysctl net.ipv4.ip_forward | tee -a "$REPORT_FILE"
}

# 5. IP and Network Configuration Checks
audit_ip_config() {
    log_to_report "\n=== IP Configuration Audit ==="
    log_to_report "IP addresses assigned to the server:"
    ip addr show | grep inet | tee -a "$REPORT_FILE"
    
    log_to_report "\nPublic vs Private IPs:"
    for ip in $(ip addr show | grep inet | awk '{print $2}' | cut -d'/' -f1); do
        if [[ $ip =~ ^10\.|^172\.(1[6-9]|2[0-9]|3[0-1])\.|^192\.168\. ]]; then
            log_to_report "$ip is a private IP"
        else
            log_to_report "$ip is a public IP"
        fi
    done
}

# 6. Security Updates and Patching
audit_updates() {
    log_to_report "\n=== Security Updates ==="
    if command -v apt >/dev/null; then
        apt update >/dev/null 2>&1
        log_to_report "Available security updates:"
        apt list --upgradable 2>/dev/null | grep security | tee -a "$REPORT_FILE"
    else
        log_to_report "Package manager not supported (apt required)"
    fi
}

# 7. Log Monitoring
audit_logs() {
    log_to_report "\n=== Log Monitoring ==="
    log_to_report "Recent SSH login attempts:"
    grep "sshd.*Failed" /var/log/auth.log | tail -n 10 | tee -a "$REPORT_FILE"
}

# 8. Custom Security Checks
audit_custom_checks() {
    log_to_report "\n=== Custom Security Checks ==="
    if [[ -f "$CONFIG_FILE" ]]; then
        while IFS= read -r line; do
            [[ -z "$line" || "$line" =~ ^# ]] && continue
            log_to_report "Running custom check: $line"
            eval "$line" >> "$REPORT_FILE" 2>&1
        done < "$CONFIG_FILE"
    else
        log_to_report "No custom checks defined (config file not found)"
    fi
}

# Main function
main() {
    log_to_report "=== Security Audit Report - $(date) ==="
    audit_users_groups
    audit_file_permissions
    audit_services
    audit_firewall_network
    audit_ip_config
    audit_updates
    audit_logs
    audit_custom_checks
    log_to_report "\n=== Audit Complete ==="
    echo "Audit report saved to $REPORT_FILE"
}

main