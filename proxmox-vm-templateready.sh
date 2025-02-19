#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root!" >&2
    exit 1
fi

# Install Cloud-Init
echo "Installing Cloud-Init..."
apt update && apt install -y cloud-init
if [[ $? -ne 0 ]]; then
    echo "Failed to install Cloud-Init. Exiting..." >&2
    exit 1
fi

echo "Cloud-Init installed successfully."

# Remove existing SSH host keys
echo "Removing SSH host keys to allow regeneration on first boot..."
rm -f /etc/ssh/ssh_host_*
echo "SSH host keys removed."

# Reset machine ID
echo "Resetting machine ID to ensure uniqueness in cloned VMs..."
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id
echo "Machine ID reset successfully."

# Clean up package cache
echo "Cleaning up system..."
apt autoremove -y && apt clean
echo "System cleaned."

# Shutdown the VM
echo "Shutting down the VM to prepare for templating..."
poweroff

