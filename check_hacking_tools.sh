#!/bin/bash


check_packages=("nmap" "msf" "metasploit" "wireshark" "aircrack-ng" "john" "hydra" "nikto" "sqlmap" "netcat" "maltego" "gobuster" "ettercap" "nfs" "cryptocat" "ophcrack")

installed_packages=$(dpkg -l | awk '{print $2}')


for installed in $installed_packages; do

        if [[ " ${check_packages[@]} " =~ " ${installed} " ]]; then
                echo "INSTALLED: $installed"
        fi
done
