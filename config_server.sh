#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

# Check root permission
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root permission"
    exit 1
fi

# Change ssh port
SSH_PORT=2200
sed -i "s/Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config

# Configure Uncomplecate Firewall(UFW)
ufw default deny incoming
ufw default allow outgoing

ufw allow $SSH_PORT/tcp
ufw allow www
ufw allow ntp

# Configure the local timezone to UTF
echo "Etc/UTC" | tee /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata

# Create user
USER_NAME="grader"
USER_HOME="/home/$USER_NAME"

# Add hostname to hosts
echo "127.0.0.1 $(cat /etc/hostname)" >> /etc/hosts

# Create User without password
adduser --disabled-password --gecos "" $USER_NAME
passwd -d $USER_NAME

# Give sudo permission to user
echo "$USER_NAME ALL=(ALL) PASSWD:ALL" > /etc/sudoers.d/$USER_NAME

# Copy key
cp -r /root/.ssh $USER_HOME/
chmod 700 $USER_HOME/.ssh
chmod 644 $USER_HOME/.ssh/authorized_keys
chown grader:grader -R $USER_HOME/.ssh

# Disable root login
sed -i "s/PermitRootLogin without-password/PermitRootLogin no/" /etc/ssh/sshd_config
echo "AllowUsers grader" >> /etc/ssh/sshd_config
service ssh restart
rm -r /root/.ssh

# Enable firewall
yes | ufw enable
