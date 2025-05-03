#!/bin/bash

# Server Hardening Script for Linux Servers
# Usage: sudo ./harden_server.sh

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

# Define report file
REPORT_FILE="../reports/audit_report.txt"

# Function to log messages to report
log_to_report() {
    echo -e "$1" | tee -a "$REPORT_FILE"
}

# 1. SSH Configuration
harden_ssh() {
    log_to_report "\n=== Hardening SSH Configuration ==="
    SSH_CONFIG="/etc/ssh/sshd_config"
    
    # Disable root login and password authentication
    sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG"
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' "$SSH_CONFIG"
    
    # Restart SSH service
    systemctl restart sshd
    log_to_report "SSH hardened: root login and password authentication disabled"
}

# 2. Disable IPv6 (if not required)
harden_ipv6() {
    log_to_report "\n=== Disabling IPv6 ==="
    echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
    sysctl -p
    log_to_report "IPv6 disabled"
}

# 3. Secure Bootloader
harden_bootloader() {
    log_to_report "\n=== Securing GRUB Bootloader ==="
    GRUB_FILE="/etc/grub.d/40_custom"
    echo 'set superusers="admin"' >> "$GRUB_FILE"
    echo 'password_pbkdf2 admin grub.pbkdf2.sha512.10000.<your_hashed_password>' >> "$GRUB_FILE"
    update-grub
    log_to_report "GRUB bootloader password set"
}

# 4. Firewall Configuration
harden_firewall() {
    log_to_report "\n=== Configuring Firewall ==="
    if command -v ufw >/dev/null; then
        ufw default deny incoming
        ufw default allow outgoing
        ufw allow ssh
        ufw enable
        log_to_report "UFW configured with default deny and SSH allowed"
    else
        log_to_report "UFW not installed, skipping firewall configuration"
    fi
}

# 5. Automatic Updates
harden_updates() {
    log_to_report "\n=== Configuring Automatic Updates ==="
    if command -v apt >/dev/null; then
        apt install -y unattended-upgrades
        dpkg-reconfigure --priority=low unattended-upgrades
        log_to_report "Unattended upgrades configured"
    else
        log_to_report "Package manager not supported (apt required)"
    fi
}

# Main function
main() {
    log_to_report "=== Server Hardening Report - $(date) ==="
    harden_ssh
    harden_ipv6
    harden_bootloader
    harden_firewall
    harden_updates
    log_to_report "\n=== Hardening Complete ==="
    echo "Hardening report appended to $REPORT_FILE"
}

main