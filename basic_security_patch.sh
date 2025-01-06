#!/bin/bash

# make sure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Update package list and upgrade system
update_system() {
    echo "Updating system packages..."
    apt update -y && apt upgrade -y
    echo "---------System update complete--------"
}

# enforce password policies
enforce_password_policy() {
    echo "--------Configuring password policies----------"

    # Minimum password length
    sed -i 's/^PASS_MIN_LEN.*/PASS_MIN_LEN   13/' /etc/login.defs

    # Password expiration policies
    sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs
    sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   7/' /etc/login.defs
    sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   14/' /etc/login.defs

    echo "----------Password policies configured---------"
}

# disable potentially harmful services
disable_unnecessary_services() {
    echo "----------Disabling unnecessary services---------"

    # Example services to disable (adjust based on your environment)
    services=(
        "telnet"
        "ftp"
        "rsh"
        "rexec"
    )

    for service in "${services[@]}"; do
        systemctl disable "$service" 2>/dev/null
        systemctl stop "$service" 2>/dev/null
    done

    echo "--------Unnecessary services disabled-----------"
}



# start firewall
setup_firewall() {
    echo "----------Setting up firewall----------"

    if command -v ufw >/dev/null 2>&1; then
        ufw default deny incoming
        ufw default allow outgoing
        ufw allow ssh
        ufw enable
    elif command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --set-default-zone=block
        firewall-cmd --permanent --add-service=ssh
        firewall-cmd --reload
    else
        echo "No firewall management tool found. Please configure manually."
    fi

    echo "-----------Firewall setup complete-----------"
}

# configure SSH settings
secure_ssh() {
    echo "-------Securing SSH settings---------"

    SSH_CONFIG="/etc/ssh/sshd_config"

    sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG"
    sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' "$SSH_CONFIG"
    sed -i 's/^#X11Forwarding.*/X11Forwarding no/' "$SSH_CONFIG"
    sed -i 's/^#MaxAuthTries.*/MaxAuthTries 3/' "$SSH_CONFIG"

    systemctl restart sshd
    echo "---------SSH settings secured----------"
}

# install fail2ban
install_fail2ban() {
    echo "--------Installing and configuring Fail2Ban--------"

    if command -v apt >/dev/null 2>&1; then
        apt install fail2ban -y
    elif command -v yum >/dev/null 2>&1; then
        yum install fail2ban -y
    fi

    systemctl enable fail2ban
    systemctl start fail2ban

    echo "---------Fail2Ban installed and running-----------"
}

# Main function
main() {
    update_system
    enforce_password_policy
    disable_unnecessary_services
    secure_ssh
    setup_firewall
    install_fail2ban
    echo "---------------------------System security hardening complete-------------------------------------"
}

main
