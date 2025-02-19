#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root!" >&2
    exit 1
fi

# Ask for the number of VMs to create
read -p "Enter the number of VMs to create: " VM_COUNT

# Ask for the template ID
read -p "Enter the Proxmox template ID: " TEMPLATE_ID

# Ask for the base VM name
read -p "Enter the base name for the VMs: " VM_NAME
VM_NAME=$(echo "$VM_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9-')

# Ensure VM name is valid
if [[ -z "$VM_NAME" ]]; then
    echo "Invalid VM name. Exiting..." >&2
    exit 1
fi

# Ask whether to power on the VMs after creation
read -p "Do you want to power on the VMs after creation? (yes/no): " POWER_ON

# Create the specified number of VMs
for ((i = 1; i <= VM_COUNT; i++)); do
    VM_ID=$(pvesh get /cluster/nextid)
    FINAL_VM_NAME="${VM_NAME}-${VM_ID}"
    
    echo "Creating VM: $FINAL_VM_NAME with ID $VM_ID from template ID $TEMPLATE_ID..."
    qm clone $TEMPLATE_ID $VM_ID --name "$FINAL_VM_NAME" --full 1
    
    if [[ $? -ne 0 ]]; then
        echo "Failed to create VM: $FINAL_VM_NAME" >&2
        exit 1
    fi

    echo "VM $FINAL_VM_NAME created successfully."

    if [[ "$POWER_ON" =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "Powering on VM: $FINAL_VM_NAME..."
        qm start $VM_ID
    fi

done

echo "VM creation process completed."

