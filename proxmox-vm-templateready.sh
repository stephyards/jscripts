#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root!" >&2
    exit 1
fi

# Detect Linux distribution
DISTRO="$(. /etc/os-release && echo "$ID")"
echo "Detected Linux distribution: $DISTRO"

# Install Cloud-Init and QEMU Guest Agent based on distribution
case "$DISTRO" in
    ubuntu|debian|kali)
        echo "Installing Cloud-Init and QEMU Guest Agent for Debian-based system..."
        apt update && apt install -y cloud-init qemu-guest-agent
        ;;
    centos|rhel|rocky|almalinux)
        echo "Installing Cloud-Init and QEMU Guest Agent for RHEL-based system..."
        yum install -y cloud-init qemu-guest-agent
        ;;
    fedora)
        echo "Installing Cloud-Init and QEMU Guest Agent for Fedora..."
        dnf install -y cloud-init qemu-guest-agent
        ;;
    *)
        echo "Unsupported distribution: $DISTRO" >&2
        exit 1
        ;;
esac

if [[ $? -ne 0 ]]; then
    echo "Failed to install Cloud-Init or QEMU Guest Agent. Exiting..." >&2
    exit 1
fi

echo "Cloud-Init and QEMU Guest Agent installed successfully."

# Enable and start QEMU Guest Agent
systemctl enable --now qemu-guest-agent

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
case "$DISTRO" in
    ubuntu|debian|kali)
        apt autoremove -y && apt clean
        ;;
    centos|rhel|rocky|almalinux)
        yum autoremove -y && yum clean all
        ;;
    fedora)
        dnf autoremove -y && dnf clean all
        ;;
esac

echo "System cleaned."

# Shutdown the VM
echo "Shutting down the VM to prepare for templating..."
poweroff

