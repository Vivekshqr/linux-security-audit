Linux Security Audit and Hardening Script
This Bash script automates security audits and hardening for Linux servers, ensuring compliance with stringent security standards. It’s modular, reusable, and configurable via a config.conf file.
Features

User and group audits (UID 0, passwordless accounts)
File and directory permission checks (world-writable, .ssh, SUID/SGID)
Service audits (running services, unauthorized services)
Firewall and network security checks (open ports, IP forwarding)
IP configuration audits (public vs. private IPs, SSH exposure)
Security updates and log monitoring
Hardening: SSH, IPv6, bootloader, firewall, automatic updates
Custom security checks via configuration
Reporting and optional email alerts

Prerequisites

Linux server (Ubuntu/Debian recommended)
Root privileges
Installed packages: apt, iptables, net-tools, mailutils (for email alerts)
VSCode for development (optional)

Setup

Clone the repository:git clone https://github.com/yourusername/linux-security-audit.git
cd linux-security-audit


Ensure the script is executable:chmod +x security_audit.sh


Create the reports directory:mkdir reports


Edit config.conf to customize settings (e.g., services, ports, email alerts).

Usage
Run the script as root:
sudo ./security_audit.sh


Reports are saved in reports/security_report_*.txt.
Logs are written to the path specified in config.conf.

Customization

Update ALLOWED_SERVICES and ALLOWED_PORTS in config.conf.
Add custom checks to CUSTOM_CHECKS (format: name:command).
Enable email alerts by setting EMAIL_ALERTS="yes" and specifying EMAIL_ADDRESS.

Development in VSCode

Use extensions: ShellCheck, GitLens, Bash IDE.
Clone and edit files in VSCode’s Explorer.
Commit changes using VSCode’s Source Control view.

Notes

Assumes Debian/Ubuntu (apt). For other distributions, modify package manager commands.
Replace the GRUB password placeholder in harden_bootloader with a real hash from grub-mkpasswd-pbkdf2.
Test email alerts with mailutils and a configured MTA (e.g., Postfix).

Contributing
Submit pull requests or issues on GitHub.
License
MIT License
# linux-security-audit