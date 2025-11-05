#!/bin/bash

################################################################################
# Kubernetes Worker Node Setup Script for Debian 12
# 
# This script prepares a node to join an existing Kubernetes cluster as a worker
# Run this script on each node that will be a worker
#
# Prerequisites:
# - Master node must be set up first
# - You need the join command from the master node
#
# Usage: sudo ./setup-k8s-worker.sh
################################################################################

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_input() {
    echo -e "${BLUE}[INPUT]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root or with sudo"
    exit 1
fi

print_status "Starting Kubernetes Worker Node Setup..."
echo ""

################################################################################
# STEP 1: Update System Packages
################################################################################
print_status "Step 1: Updating system packages..."

# Update the package index to get latest versions
apt update

# Upgrade all installed packages to their latest versions
apt upgrade -y

print_status "System packages updated successfully"
echo ""

################################################################################
# STEP 2: Set Hostname (Optional)
################################################################################
print_status "Step 2: Setting hostname..."

# Prompt for worker node name
print_input "Enter hostname for this worker node (e.g., worker1, worker2):"
read -p "Hostname: " WORKER_HOSTNAME

# Set hostname if provided
if [ -n "$WORKER_HOSTNAME" ]; then
    hostnamectl set-hostname $WORKER_HOSTNAME
    print_status "Hostname set to: $(hostname)"
else
    print_warning "No hostname provided, keeping current: $(hostname)"
fi
echo ""

################################################################################
# STEP 3: Disable Swap
################################################################################
print_status "Step 3: Disabling swap..."

# Kubernetes requires swap to be disabled for proper operation
# This turns off swap immediately
swapoff -a

# This comments out swap entries in fstab to persist after reboot
# The sed command finds lines with ' swap ' and comments them out
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Verify swap is disabled (should show 0B)
print_status "Swap status (should show 0B):"
free -h | grep Swap

# Double-check swap is actually off
if [ $(swapon --show | wc -l) -eq 0 ]; then
    print_status "Swap successfully disabled"
else
    print_error "Swap is still active!"
    exit 1
fi
echo ""

################################################################################
# STEP 4: Load Required Kernel Modules
################################################################################
print_status "Step 4: Loading required kernel modules..."

# Create a configuration file to load necessary kernel modules at boot
# overlay: Required for OverlayFS storage driver used by containers
# br_netfilter: Required for iptables to see bridged traffic (pod networking)
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# Load the modules immediately (without waiting for reboot)
modprobe overlay
modprobe br_netfilter

# Verify modules are loaded successfully
print_status "Verifying kernel modules are loaded..."
if lsmod | grep -q overlay && lsmod | grep -q br_netfilter; then
    print_status "Kernel modules loaded successfully"
    lsmod | grep -E 'overlay|br_netfilter'
else
    print_error "Failed to load required kernel modules"
    exit 1
fi
echo ""

################################################################################
# STEP 5: Configure Sysctl Parameters
################################################################################
print_status "Step 5: Configuring sysctl parameters for Kubernetes..."

# Create sysctl configuration for Kubernetes networking
# These settings are critical for proper pod networking
cat <<EOF | tee /etc/sysctl.d/k8s.conf
# Enable IP forwarding - allows the node to forward traffic between pods
net.ipv4.ip_forward = 1

# Allow iptables to see bridged IPv4 traffic
# Required for kube-proxy to function correctly
net.bridge.bridge-nf-call-iptables = 1

# Allow iptables to see bridged IPv6 traffic
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply the sysctl settings immediately without reboot
sysctl --system

# Verify the settings were applied
print_status "Verifying sysctl parameters..."
sysctl net.ipv4.ip_forward net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables

print_status "Sysctl parameters configured successfully"
echo ""

################################################################################
# STEP 6: Install Container Runtime (containerd)
################################################################################
print_status "Step 6: Installing containerd container runtime..."

# Install required dependencies for adding Docker repository
# These packages allow apt to use HTTPS repositories
apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Create directory for apt keyrings if it doesn't exist
mkdir -p /etc/apt/keyrings

# Download and add Docker's official GPG key
# This key is used to verify the authenticity of packages
print_status "Adding Docker GPG key..."
curl -fsSL https://download.docker.com/linux/debian/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository to apt sources
# We use Docker's repository to install containerd
print_status "Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index with new repository
apt update

# Install containerd.io package
# containerd is the container runtime that will run pods
print_status "Installing containerd..."
apt install -y containerd.io

print_status "containerd installed successfully"
echo ""

################################################################################
# STEP 7: Configure containerd
################################################################################
print_status "Step 7: Configuring containerd..."

# Create containerd configuration directory
mkdir -p /etc/containerd

# Generate default containerd configuration file
print_status "Generating containerd configuration..."
containerd config default | tee /etc/containerd/config.toml > /dev/null

# CRITICAL CONFIGURATION: Enable SystemdCgroup
# Kubernetes requires systemd cgroup driver for stability and proper resource management
# This changes the cgroup driver from cgroupfs to systemd
print_status "Enabling SystemdCgroup driver (required for Kubernetes)..."
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Verify the change was made
if grep -q "SystemdCgroup = true" /etc/containerd/config.toml; then
    print_status "SystemdCgroup successfully enabled"
else
    print_error "Failed to enable SystemdCgroup"
    exit 1
fi

# Restart containerd to apply the new configuration
print_status "Restarting containerd service..."
systemctl restart containerd

# Enable containerd to start automatically on boot
systemctl enable containerd

# Verify containerd is running properly
if systemctl is-active --quiet containerd; then
    print_status "containerd is running and properly configured"
else
    print_error "containerd failed to start - checking logs..."
    systemctl status containerd
    exit 1
fi
echo ""

################################################################################
# STEP 8: Install Kubernetes Components
################################################################################
print_status "Step 8: Installing Kubernetes components..."

# Add Kubernetes repository GPG key
# This key verifies the authenticity of Kubernetes packages
print_status "Adding Kubernetes GPG key..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | \
    gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add Kubernetes repository to apt sources
# Using v1.28 stable channel (should match master node version)
print_status "Adding Kubernetes repository..."
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | \
    tee /etc/apt/sources.list.d/kubernetes.list

# Update package index with Kubernetes repository
apt update

# Install Kubernetes components:
# - kubelet: The primary node agent that runs on each worker node
# - kubeadm: Tool used to join the worker to the cluster
# - kubectl: Command-line tool (useful for debugging on worker nodes)
print_status "Installing kubelet, kubeadm, and kubectl..."
apt install -y kubelet kubeadm kubectl

# Hold these packages at current version
# Prevents accidental upgrades which could cause version mismatch issues
# Kubernetes upgrades should be planned and coordinated across the cluster
apt-mark hold kubelet kubeadm kubectl

# Enable kubelet service to start on boot
# Note: kubelet will crash-loop until the node joins a cluster (this is normal)
systemctl enable kubelet

# Display installed versions
print_status "Kubernetes components installed successfully"
print_status "Installed versions:"
kubeadm version | head -1
kubelet --version
kubectl version --client --short 2>/dev/null || kubectl version --client
echo ""

################################################################################
# STEP 9: Verify Prerequisites
################################################################################
print_status "Step 9: Verifying all prerequisites..."

# Run kubeadm preflight checks
# This validates that the system is ready to join a cluster
print_status "Running kubeadm preflight checks..."
kubeadm config images pull

if [ $? -eq 0 ]; then
    print_status "All container images pulled successfully"
else
    print_warning "Some images failed to pull, but continuing..."
fi
echo ""

################################################################################
# STEP 10: Display Network Information
################################################################################
print_status "Step 10: Network configuration..."

# Display current IP addresses
# You'll need this information for the join command
print_status "Network interfaces and IP addresses:"
ip -br addr show | grep -v "127.0.0.1"
echo ""

# Get primary IP address
PRIMARY_IP=$(ip route get 1 | awk '{print $7;exit}')
print_status "Primary IP address: $PRIMARY_IP"
echo ""

################################################################################
# STEP 11: Setup Complete - Ready to Join
################################################################################
print_status "=== WORKER NODE SETUP COMPLETE ==="
echo ""

print_status "This worker node is now ready to join the Kubernetes cluster!"
echo ""

print_warning "NEXT STEPS:"
echo ""
echo "1. On your MASTER node, get the join command by running:"
echo "   ${GREEN}kubeadm token create --print-join-command${NC}"
echo ""
echo "2. Copy the entire join command output"
echo ""
echo "3. On THIS worker node, run the join command as root:"
echo "   ${GREEN}sudo kubeadm join <master-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>${NC}"
echo ""
echo "Example join command:"
echo "   sudo kubeadm join 192.168.1.10:6443 --token abcdef.0123456789abcdef \\"
echo "       --discovery-token-ca-cert-hash sha256:1234567890abcdef..."
echo ""

print_warning "IMPORTANT NOTES:"
echo "  - The join token expires after 24 hours"
echo "  - Make sure this node can reach the master node on port 6443"
echo "  - After joining, verify on master with: kubectl get nodes"
echo ""

# Create a reminder file
cat > /root/JOIN-INSTRUCTIONS.txt <<EOF
================================================================================
KUBERNETES WORKER NODE - JOIN INSTRUCTIONS
================================================================================

This worker node is ready to join the cluster!

STEP 1: Get the join command from master node
----------------------------------------------
On the master/control-plane node, run:
  kubeadm token create --print-join-command

STEP 2: Run the join command on this worker node
-------------------------------------------------
Copy the output from Step 1 and run it on this node with sudo:
  sudo kubeadm join <master-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>

STEP 3: Verify the node joined successfully
--------------------------------------------
On the master node, run:
  kubectl get nodes

You should see this worker node ($(hostname)) in the list.

TROUBLESHOOTING
---------------
If join fails, check:
  1. Network connectivity to master: ping <master-ip>
  2. Port 6443 accessible: telnet <master-ip> 6443
  3. Kubelet logs: sudo journalctl -u kubelet -f
  4. Token not expired: tokens expire after 24 hours

To reset this node if needed:
  sudo kubeadm reset
  sudo rm -rf /etc/cni/net.d
  sudo rm -rf /var/lib/kubelet/*

Worker Node Information:
  Hostname: $(hostname)
  Primary IP: $PRIMARY_IP
  Setup Date: $(date)

================================================================================
EOF

print_status "Join instructions saved to: /root/JOIN-INSTRUCTIONS.txt"
echo ""

################################################################################
# STEP 12: Final System Status
################################################################################
print_status "=== SYSTEM STATUS ==="
echo ""

print_status "Hostname: $(hostname)"
print_status "Primary IP: $PRIMARY_IP"
print_status "Swap: $(free -h | grep Swap | awk '{print $2}')"
print_status "containerd: $(systemctl is-active containerd)"
print_status "kubelet: $(systemctl is-active kubelet) (will be active after joining cluster)"
echo ""

print_status "Worker node setup completed successfully!"
print_status "Ready to join the Kubernetes cluster."
echo ""

# Offer to wait for join command input
print_input "Do you want to join the cluster now? (y/n)"
read -p "Answer: " JOIN_NOW

if [[ $JOIN_NOW =~ ^[Yy]$ ]]; then
    echo ""
    print_input "Paste the join command from your master node:"
    print_warning "(It should start with: sudo kubeadm join...)"
    read -p "Join command: " JOIN_COMMAND
    
    if [ -n "$JOIN_COMMAND" ]; then
        print_status "Executing join command..."
        eval $JOIN_COMMAND
        
        if [ $? -eq 0 ]; then
            print_status "Successfully joined the cluster!"
            echo ""
            print_status "On the master node, run this command to see this node:"
            echo "  kubectl get nodes"
        else
            print_error "Failed to join cluster. Check the command and try again."
        fi
    else
        print_warning "No command entered. You can join later manually."
    fi
else
    print_status "You can join the cluster later using the join command from master."
fi

echo ""
print_status "All done! Worker node is ready."
